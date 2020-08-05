---
layout: default
title: Strict YAML deserialization with marshmallow
---

## The problem

- I want to read some not so simple config from .yaml file. 
- I have config structure described as dataclasses.
- I want to all type cheks have been performed and in case of invalid data exception will be raised.

So basicly I want something like

```python
def strict_load_yaml(yaml: str, loaded_type: Type[Any]):
    """
    Here is some magic
    """
    pass
```

And then use it like this:

```python
@dataclass
class MyConfig:
    """
    Here is object tree
    """
    pass

try:
    config = strict_load_yamp(open("config.yaml", "w").read(), MyConfig)
except Exception:
    logging.exception("Config is invalid")
```

## Config classes

Here is my `config.py` file with example dataclasses:

```python
from dataclasses import dataclass
from enum import Enum
from typing import Optional


class Color(Enum):
    RED = "red"
    GREEN = "green"
    BLUE = "blue"


@dataclass
class BattleStationConfig:
    @dataclass
    class Processor:
        core_count: int
        manufacturer: str

    processor: Processor
    memory_gb: int
    led_color: Optional[Color] = None

```

## Solution that didn't work

That is very common patternt, right?
It must be very easy. 
Just import standard yaml library and problem solved?

So I imported [PyYaml](https://github.com/yaml/pyyaml) and call `load` method:

```python
from pprint import pprint

from yaml import load, SafeLoader


yaml = """
processor:
  core_count: 8
  manufacturer: Intel
memory_gb: 8
led_color: red
"""

loaded = load(yaml, Loader=SafeLoader)
pprint(loaded)

```

and I have got:

```
{'led_color': 'red',
 'memory_gb': 8,
 'processor': {'core_count': 8, 'manufacturer': 'Intel'}}
```

Yaml loaded just fine, but it is dict. 
No problem, I can pass it as `**args` constructor and...

```python
BattleStationConfig(processor={'core_count': 8, 'manufacturer': 'Intel'}, memory_gb=8, led_color='red')
```

and result is:

```
BattleStationConfig(processor={'core_count': 8, 'manufacturer': 'Intel'}, memory_gb=8, led_color='red')
```

Wow! Easy! But... Wait. Is processor field a dict? Damn it.

Python don't perform type checking at constructor and do not parse `Processor` class.
Well, time to go to stackowerflow.

## Solution that required yaml tags and almost works

I read stackowerflow answers and PyYaml documentation and fild out that you can mark your yaml doc with tags for types. 
Your classes must be descendants of `YAMLObject` and so my `config_with_tag.py` will look like this:

```python
from dataclasses import dataclass
from enum import Enum
from typing import Optional

from yaml import YAMLObject, SafeLoader


class Color(Enum):
    RED = "red"
    GREEN = "green"
    BLUE = "blue"


@dataclass
class BattleStationConfig(YAMLObject):
    yaml_tag = "!BattleStationConfig"
    yaml_loader = SafeLoader

    @dataclass
    class Processor(YAMLObject):
        yaml_tag = "!Processor"
        yaml_loader = SafeLoader

        core_count: int
        manufacturer: str

    processor: Processor
    memory_gb: int
    led_color: Optional[Color] = None
```

And loading code:


```python
from pprint import pprint

from yaml import load, SafeLoader

from config_with_tag import BattleStationConfig


yaml = """
--- !BattleStationConfig
processor: !Processor
  core_count: 8
  manufacturer: Intel
memory_gb: 8
led_color: red
"""

a = BattleStationConfig

loaded = load(yaml, Loader=SafeLoader)
pprint(loaded)
```

And what I will get?

```
BattleStationConfig(processor=BattleStationConfig.Processor(core_count=8, manufacturer='Intel'), memory_gb=8, led_color='red')
```

Good. But my YAML is full of tags and lost its readability. And `Color` is still string. So I can just add `YAMLObject` to parent classes? Right? No.

```python
class Color(Enum, YAMLObject):
    RED = "red"
    GREEN = "green"
    BLUE = "blue"
```

Will lead to:

```
TypeError: metaclass conflict: the metaclass of a derived class must be a (non-strict) subclass of the metaclasses of all its bases
```

I didn't find a quick way to resolve it. And I did want to add tags to my yaml so I decided to keep looking for a solution.

## Solution with marshmallow

I found recommendation to use marshmallow to parse dict generated fron JSON object. 
I decided that these cases are the same as mine only uses JSON instead of YAML. 
And so I tried to use `class_schema` generator for dataclass schema:

```python
from pprint import pprint

from yaml import load, SafeLoader
from marshmallow_dataclass import class_schema

from config import BattleStationConfig


yaml = """
processor:
  core_count: 8
  manufacturer: Intel
memory_gb: 8
led_color: red
"""

loaded = load(yaml, Loader=SafeLoader)
pprint(loaded)

BattleStationConfigSchema = class_schema(BattleStationConfig)

result = BattleStationConfigSchema().load(loaded)
pprint(result)

```

And I get:

```
marshmallow.exceptions.ValidationError: {'led_color': ['Invalid enum member red']}
```

So, marshmallow wants enum name, not value. I can change my yaml to:

```yaml
processor:
  core_count: 8
  manufacturer: Intel
memory_gb: 8
led_color: RED
```

And I will get my ideally desererialized object:

```
BattleStationConfig(processor=BattleStationConfig.Processor(core_count=8, manufacturer='Intel'), memory_gb=8, led_color=<Color.RED: 'red'>)
```

But I felt there was a way to use my original yaml. 
So I've explored marshmallow documentation and found folowing lines:

> Setting `by_value=True`. This will cause both dumping and loading to use the value of the enum.

Turn out, you can pass this configuration to `metadata` dictionary of `field` generator from dataclasses like this:

```python
@dataclass
class BattleStationConfig:
    led_color: Optional[Color] = field(default=None, metadata={"by_value": True})
```

And I will get parsed object from my original yaml.

## Magic function

And after all I can collect my magic function:

```python
def strict_load_yaml(yaml: str, loaded_type: Type[Any]):
    schema = class_schema(loaded_type)
    return schema().load(load(yaml, Loader=SafeLoader))
```

This function can require additional set up for dataclass but solve my problem and do not require tags in yaml.

## Some words about ForwardRef

If you define your dataclasees with forward reference (string with class name) marshmallow can be confused and didn't parse your classes.

For example this configuration

```python
from dataclasses import dataclass, field
from enum import Enum
from typing import Optional, ForwardRef


@dataclass
class BattleStationConfig:
    processor: ForwardRef("Processor")
    memory_gb: int
    led_color: Optional["Color"] = field(default=None, metadata={"by_value": True})

    @dataclass
    class Processor:
        core_count: int
        manufacturer: str


class Color(Enum):
    RED = "red"
    GREEN = "green"
    BLUE = "blue"

```

will lead to 

```
marshmallow.exceptions.RegistryError: Class with name 'Processor' was not found. You may need to import the class.
```

And if we move `Processor` class upper marshmallow will lost `Color` with the same error. 
So keep your classes without ForwardRef if possible.

## Code

All code available on [GitHub repository](https://github.com/kirillsulim/python-strict-yaml-parsing).
