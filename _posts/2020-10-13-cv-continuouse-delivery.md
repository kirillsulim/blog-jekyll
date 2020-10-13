---
layout: default
title: "CV continuouse delivery"
---

TLDR: I've used [dogebuild](https://github.com/dogebuild/dogebuild) and [travis](https://travis-ci.com/) to create continuous integration pipeline for my CV.

## The perfect CV

For many years I've learn how to create most effective CV.
I found the talk [‎How to write a Perl CV that will get you hired‎](https://www.youtube.com/watch?v=BNRVKngFOCY) by Peter Sergeant very useful as inspiration and my CV was based on this talk ideas for many years.


## The problem

At this moment in my career I need 4 CV.
One for developer position and one for team-lead position.
That must be multiplied by two languages (english and russian) and we get 4 CV.

If I would create those CV manually I will face a lot of duplications and as a programmer I try to avoid any duplication.
Also I would like to keep my .pdf files, my linkedin profile and my hh.ru profile consistent.


## Solution description

I would like to have .yaml configuration file with all my data.
With every commit in master branch I would like to get updates on my linkedin profile, hh.ru profile and get .pdf files ready to be sent to HR.


## Model

All my data is stored in python dataclass names Data:

```python
@dataclass
class Data:
    personal: Personal = None
    contacts: Optional[Contacts] = None
    about_me: Optional[AboutMe] = None
    education: List[Education] = field(default_factory=list)
    work_experience: List[WorkExperience] = field(default_factory=list)
```

**Personal info**

Personal info is just a name and surname now.

```python
@dataclass
class Personal:
    name: Union[str, MultilangStr]
    surname: Union[str, MultilangStr]
```

**Contacts**

Contacts was the part of personal info but then I decided to separate them to get more simple templates.
Contacts class is very simple:

```python
@dataclass
class Contacts:
    phone: Optional[str] = None
    email: Optional[str] = None
    telegram: Optional[str] = None
    github: Optional[str] = None
    site: Optional[str] = None
    skype: Optional[str] = None
```

but there is one hack.
To allow me to get more flexible contacts part building I use special preprocessor to exclude some contacts with fake profiles:

```python
def _contacts_preprocessor(contacts: Contacts, profiles: Set[str]) -> Contacts:
    args = {}
    for contact_type, value in contacts.__dict__.items():
        if not f"exclude_{contact_type}" in profiles:
            args[contact_type] = value
    return Contacts(**args)
```

**About me**

This is simnple list of `ProfiledMultilangStr` but at this moment it is empty for me data file.

```python
@dataclass
class AboutMe:
    text_parts: List[Union[str, ProfiledMultilangStr]]
```

**Education**

Education part is list of `Educaton` class:

```python
@dataclass
class Education:
    university: Union[str, MultilangStr]
    faculty: Union[str, MultilangStr]
    speciality: Union[str, MultilangStr]
    from_date: Optional[date] = None
    to_date: Optional[date] = None
```

It contains university and faculty names, dates and degree.

**Work expirience**

Work expirience is list of objects of class with the same name:

```python
@dataclass
class Organisation:
    name: Union[str, MultilangStr]


@dataclass
class WorkExperience:
    organisation: Organisation
    position: Union[str, MultilangStr]
    bullets: List[Union[str, ProfiledMultilangStr]] = field(default_factory=list)
    technologies: List[Union[str, ProfiledStr]] = field(default_factory=list)
    from_date: Optional[date] = None
    to_date: Optional[date] = None
    current: bool = False
```

`Organisation` is separate class in case I would add additional info in future.

Bullets and technologies list is insired by the talk I mentioned at the beginning.
Its main point that you should include in your CV:

- List of keywords to HR or software (this is technologies part)
- Some achievements for Hiring Manager (this goes to bullets)
- Some funny war stories to talk with Tech Interviewer (this part also goes to bullets part)

The rest (dates, position) is obligatory part of any CV.


### Rendering

I use `MultilangStr` class to store many languages data in the same place:

```python
@dataclass
class MultilangStr:
    ru: str
    en: str
```

To allow me to generate sligthly different CV for different positions I've created `profile` parameter to include or exclude parts of data.
Profile is supported by `ProfiledStr` and `ProfiledMultilangStr`.

```python
@dataclass
class ProfiledStr:
    value: str
    profile: Optional[List[str]] = field(default_factory=list)


@dataclass
class ProfiledMultilangStr(MultilangStr):
    profile: Optional[List[str]] = field(default_factory=list)
```

Raw data and rendered data is almost the same, except that all `MultilangStr`, `ProfiledStr` and `ProfiledMultilangStr` became usual strings or will not be included.
So I cheated and my prepared data structure is the same as raw.
To support such behavior I had to use `Union[str, MultilangStr]` for any `MultilangStr` field. The same is right for the rest of string types.

To get rendered data I use folowing recursive function:

```python
def _is_simple_type(obj: Any) -> bool:
    return obj is None or isinstance(obj, (str, date, bool, int, float))


def _resolve_lang_and_profiled_strings(obj: Any, lang: str, profiles: Set[str]) -> Any:
    if _is_simple_type(obj):
        return obj
    elif isinstance(obj, Iterable):
        return obj.__class__(filter(lambda o: o is not None, map(lambda it: _resolve_lang_and_profiled_strings(it, lang, profiles), obj)))
    elif isinstance(obj, MultilangStr):
        return getattr(obj, lang)
    elif isinstance(obj, ProfiledStr):
        if obj.profile is None or obj.profile in profiles:
            return obj.value
        else:
            return None
    elif isinstance(obj, ProfiledMultilangStr):
        if obj.profile is None or obj.profile in profiles:
            return getattr(obj, lang)
        else:
            return None
    elif isinstance(obj, Contacts):
        return _contacts_preprocessor(obj, profiles)
    elif is_dataclass(obj):
        args = {}
        for k, v in obj.__dict__.items():
            args[k] = _resolve_lang_and_profiled_strings(v, lang, profiles)
        return obj.__class__(**args)
    else:
        raise Exception(f"Unsupported class {obj.__class__}")
```


## Dogebuild

Dogebuild is general purpose build system.
Dogebuild is designed to be some kind of gradle analog for C++ build.
But its plugin system allow you to use it for any build process.
And [make mode](https://dogebuild.readthedocs.io/en/latest/make-mode/) allow you to skip plugin creation and just use tasks for simple builds.

I use dogebuild to manage tasks dependencies, e.g. to build pdf files before load them to github.


## Pdf building

I use Latex markup to generate .pdf files with CV.
I build .tex document with [pylatex](https://github.com/JelteF/PyLaTeX).

To avoid long setup of all Latex installation on travis I decided to use docker container with full Latex installation.
To make pylatex work with docker I've used following workaround:

```python
command = ["docker", "run", "-it", "--rm", "--user", f"{os.getuid()}:{os.getgid()}", "-v", f"{out_dir}:{out_dir}",
                       "-w", f"{out_dir}", "thomasweise/docker-texlive-full", "/usr/bin/pdflatex"]
doc.generate_pdf(out_file, compiler=command[0], compiler_args=command[1:])
```

Basically I've used `docker` as a latex compiler and volumes setup, container name and binary inside container are just compiler arguments.


## Continuouse integration

To run CI pipeline I use [travis](https://travis-ci.com).
There is no complex setup for travis as far as dogebuild took all hard work.
All I needed is to install python dependencies, pull docker container and set up credentials for github:

```yaml
language: python
python:
  - "3.8"
services:
  - docker
install:
  - pip install -r requirements.txt
  - docker pull thomasweise/docker-texlive-full
script:
  - doge render_pdf --profiles pdf
  - doge render_md --langs en --profiles md_for_github
  - doge commit_md_to_github --langs en --profiles md_for_github
  - doge release_pdf --profiles pdf
branches:
  only:
  - master
```


## The bad part

Linkedin have API to update profile but as far as I know now I cannot get acces to that API.

Hh.ru is better and its API for CV update is free to anyone.
However there was more than a week since I created request to access to that API.
