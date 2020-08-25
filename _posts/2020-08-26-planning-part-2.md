---
layout: default
title: React blog project planning part 2
---

## Decomposition

I decomposed my project into following user stories

- Learn Zurb Foundation: As a Developer I want to learn basic usages of Zurb Foundation so I can develop interfaces			
  - Learn Zurb Foundation: As a Developer I want to learn basic usages of Zurb Foundation so I can develop interfaces
- Learn Nest.js: As a Developer I want to learn nest.js so I can develop backend			
  - Create hello world Nest.js site: As a Developer I want to learn how to create hello world nest.js site so I can build backend later
  - Create form with Nest.js React and Foundation: As a Developer I want to learn how to create forms with Zurb Foundation, React and Nest,js so I can build an MVP project later
- Learn Kubernetes: As a DevOps I want to learn how to work with Kubernetes so I can set up infrastructure later
  - Simple pods in kubernetes: As a DevOps I want to learn how to run simple service in kubernetes so I can run production services later
  - Set up kubernetes on server: As a DevOps I want to learn how to set up kubernetes on server so I can set up infrastructure for production
  - Key storage with kubernetes: As a DevOps I want to learn how to store keys and passwords in kubernetes so I can set up kubernetes for production
- Infrastructure: As a Developer I want to use infrastructure so I can focus on features instead of delivery process			
  - Database migrations: As a Developer I want to have migration framework set up	so I can not to not be distracted with manual migrations
  - Data backup: As a Developer I want to have backup set up so I can not to be afraid of losing data
  - CI & CD: As a Developer I want to have continious deliverey set up so I can not to spend time on manual deploy	
  - Key storage: As a Developer I want to have key storage set up so I can not to store keys and passwords in repo or txt on instance
  - Metrics: As a DevOps I want to have metrics on services so I can understand what happens to service
  - Logging: As a Developer I want to have log service so I can debug errors
  - Tracing: As a Developer I want to have tracing on services so I can debug errors
- Image service: As a Developer I want to store images in separate service so I can use resized images in common maneer across many services
  - Upload image: As a Developer I want to have API to aloow user to upload images to storage so I can get image later on frontend
  - Get resized image: As a Developer I want to have API to get resized image with one request so I can show it in frontend
- Authorization service: As a Developer I want to authorize user across many services so I can avoid errors with authorization			
  - Register: As a Developer I want to have API to Register user so I can allow registration in many services
  - Authenticate: As a Developer I want to have API to authenticate user so I can allow user to authenticate
  - Authenticate with google: As a Developer I want to have API to log in user with google account so I can allow user to authenticate easily
- Publish: As an Author I want to Publish posts so I can promote my personal brand			
  - Authenticate: As an Author I want to log in to publisher so only me could write posts
  - Authenticate with google: As an Author I want to log in to publisher with google account so I can login easily
  - Publish on Yandex Zen: As an Author I want to publish on yandex zen so I can promote personal brand with popular blog platform
  - Publish on su0.io: As an Author I want to publish on su0.io	so I can my posts associated with my blog
  - Create post: As an Author I want to create post in .md redactor on admin panel so I can easily create and edit posts when I have no access to git repo or anithing dev-related
  - Syntax highlight: As an Author I want to have .md syntax highlighted so I can edit posts easy
  - Diagrams: As an Author I want to make diagrams in .md so I can avoid images for diagrams
- Comments: As a Reader I want to comment post so I can discuss topics			
  - Register: As a Reader I want to register so I can write comments
  - Log in: As a Reader I want to login so I can write comments
  - Log in with google: As a Reader I want to login with google account	so I can write comments without long process of log in
  - Comment: As a Reader I want to write simple comments so I can discuss posts
  - Comments with .md: As a Reader I want to write comments with formulas and images so I can be specific when discussing complex stuff with formulas

## Estimation

I fill [table in Google Sheets](https://docs.google.com/spreadsheets/d/1lOOvNDjSCl5XPfNrzS4E88az1ZR9D_s7rztrvic6jLU/edit?usp=sharing) with user stories and put estimation in two cases:

- SP50%: This is estiation in case everything goes normal
- SP90%: This is estimation in worst case

After that I calculated standard deviation and with 90% probability my project will take 94 story points.


## Stories order

My epics are highly dependent on each other so I have a strict order from the beginning. I will start from investigation of new technologies, after that I will set up infrastructure and at the end I will create services.

*Wish me luck =)*
