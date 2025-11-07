# LBAW's framework

## Introduction

This README describes how to set up the development environment for LBAW.
It uses **Laravel 12** as the application framework.

These instructions address the development with a local environment (with PHP installed) and Docker containers for PostgreSQL and pgAdmin.

For a detailed explanation of how the provided Laravel template (**Thingy!**) was built from scratch, see [Making of Template Laravel](MAKING_OF.md).

- [LBAW's framework](#lbaws-framework)
  - [Introduction](#introduction)
  - [Installing the software dependencies](#installing-the-software-dependencies)
  - [Setting up the development repository](#setting-up-the-development-repository)
  - [Installing local PHP dependencies](#installing-local-php-dependencies)
  - [Working with PostgreSQL](#working-with-postgresql)
  - [Developing the project](#developing-the-project)
  - [Laravel code structure](#laravel-code-structure)
    - [1) Routes](#1-routes)
    - [2) Controllers](#2-controllers)
    - [3) Database and Models](#3-database-and-models)
      - [Disabling timestamps](#disabling-timestamps)
      - [Defining relationships](#defining-relationships)
    - [4) Policies](#4-policies)
      - [Using the policy in a controller](#using-the-policy-in-a-controller)
    - [5) Views](#5-views)
      - [Template inheritance](#template-inheritance)
      - [Organizing templates](#organizing-templates)
    - [6) CSS](#6-css)
    - [7) JavaScript](#7-javascript)
    - [8) Configuration](#8-configuration)
      - [Environment files in this project](#environment-files-in-this-project)
      - [Updating configuration](#updating-configuration)
  - [Publishing your image](#publishing-your-image)
    - [Configure environment for production](#configure-environment-for-production)
    - [Publishing steps](#publishing-steps)
  - [Testing your image locally](#testing-your-image-locally)
    - [Inspecting the container](#inspecting-the-container)
    - [Stopping the container](#stopping-the-container)
  - [Automated Tests](#automated-tests)
    - [Running tests](#running-tests)
    - [Example feature test](#example-feature-test)


## Installing the software dependencies

To prepare your computer for development, you need to install:

* [PHP](https://www.php.net/downloads) version 8.3 or higher
* [Composer](https://getcomposer.org/) version 2.2 or higher
* [Docker Desktop](https://docs.docker.com/desktop/)


### Linux

On Ubuntu 24.04 or newer, PHP and Composer are included in the distribution.
If necessary, install PHP and Composer with:

```bash
sudo apt update
sudo apt install git composer php8.3 php8.3-mbstring php8.3-xml php8.3-pgsql php8.3-curl
```


### macOS

On macOS, install using [Homebrew](https://brew.sh/):

```bash
brew install php@8.3 composer
```

### Windows

On Windows, you have two options:

* Install PHP and Composer directly on Windows, and use Docker Desktop for Windows (**recommended**).
* Or use [Windows WSL](https://learn.microsoft.com/en-us/windows/wsl/) with Ubuntu 24.04. If you choose WSL, make sure you are running Ubuntu 24.04 inside WSL, since previous versions do not provide the required packages. After setting up WSL, follow the Ubuntu instructions above, and install Docker inside WSL.

## Setting up the development repository

**Important**: Only one group member should perform these steps.

First, ensure you have both repositories in the same folder:

* Your group's repository
* The demo repository (template-laravel)

Follow these steps to set up your development environment:

```bash
# Clone your group repository
# Replace YYYY with the year (e.g., 2024) and XX with your group number
git clone https://gitlab.up.pt/lbaw/lbawYYYY/lbawYYXX.git

# Clone the LBAW project skeleton
git clone https://gitlab.up.pt/lbaw/template-laravel.git

# Remove the Git folder from the demo folder
rm -rf template-laravel/.git

# Preserve the existing README.md
mv template-laravel/README.md template-laravel/README_lbaw.md

# Go to your repository
cd lbawYYXX

# Switch to main branch
git checkout main

# Copy all demo files
cp -r ../template-laravel/. .

# Add the new files to your repository
git add .
git commit -m "Base Laravel structure"
git push origin main
```

After these steps:

1. You'll have the project skeleton on your local machine
2. You can remove the `template-laravel` directory

For team collaboration:

1. Only one group member should perform the above steps and push changes
2. Other group members should then clone the updated repository:

```bash
git clone https://gitlab.up.pt/lbaw/lbawYYYY/lbawYYXX.git
```

3. Each group member must create their own `.env` file:

```bash
cp .env.thingy .env
```

The `.env` file contains configuration settings and is not tracked by Git (see [.gitignore](.gitignore)).


## Installing local PHP dependencies

After setting up your repository, install all local dependencies required for development:

```bash
composer install
```

If the installation fails:

1. Check your Composer version (should be 2.2 or above): `composer --version`
2. If you see errors about missing PHP extensions, ensure they are enabled in your [php.ini file](https://www.php.net/manual/en/configuration.file.php)


## Working with PostgreSQL

The _Docker Compose_ file provided sets up **PostgreSQL** and **pgAdmin4** as local Docker containers.

Start the containers from your project root:

```bash
docker compose up -d
```

Stop the containers when needed:

```bash
docker compose down
```

Open your browser and navigate to `http://localhost:4321` to access pgAdmin4.

Depending on your installation setup, you might need to use the IP address from the virtual machine providing docker instead of `localhost`.

On first use, add a local database connection with these settings:

```
hostname: postgres
username: postgres
password: password
```

Use `postgres` as hostname (not `localhost`) because _Docker Compose_ creates an internal DNS entry for container communication.


## Developing the project

You're all set up to start developing the project.
The provided skeleton includes a basic to-do list application -- **Thingy!**, which you'll modify to implement your project.

Start the development server from your project root:

```bash
# Seed database from the SQL file
# Required: first run and after database script changes
php artisan db:seed

# Start the development server
php artisan serve
```

Access the application at `http://localhost:8000`

* Username: admin@example.com
* Password: 1234

These credentials are created when seeding the database.

To stop the server: Press `Ctrl-C`


## Laravel code structure

Before you start, familiarize yourself with [Laravel's documentation](https://laravel.com/docs/12.x).

A typical web request in Laravel involves several components. Here are the key concepts.


### 1) Routes

Laravel processes web pages through its [routing](https://laravel.com/docs/12.x/routing) mechanism.
Routes are defined in `routes/web.php`. Example:

```php
Route::get('cards/{card}', [CardController::class, 'show'])->name('cards.show');
```

This route:

* Handles GET requests to `cards/{card}`
* Uses **route model binding**: Laravel automatically looks up the Card model instance that matches the {card} placeholder (by primary key id)
* Assigns the route a name: `cards.show` — useful when generating URLs in Blade with route('cards.show', $card)
* Calls the `show` method of `CardController`, passing in the resolved Card model


### 2) Controllers

[Controllers](https://laravel.com/docs/12.x/controllers) group related request handling logic into a single class.
Controllers are normally defined in the `app/Http/Controllers` folder.

```php
class CardController extends Controller
{
    /**
     * Display the details of a specific card.
     */
    public function show(Card $card): View
    {
        // Ensure the current user is authorized to view this card.
        Gate::authorize('view', $card);  

        // Eager load the card's items, ordered by id.
        $card->load('items');

        // Render the 'pages.card' view with the card and its items.
        return view('pages.card', [
            'card' => $card
        ]);
    }
```

This particular controller contains a `show` method that:

* Uses **route model binding**: the `$card` parameter is automatically resolved by Laravel from the route.
* Checks if the authenticated user is authorized to view the card using the `CardPolicy`.
* Eager loads the related items so they are available in the view (avoiding [N+1 queries](https://laravel-news.com/laravel-n1-query-problems)).
* Returns the Blade view `pages.card` with the card and its related data.


### 3) Database and Models

To access the database, we use [Eloquent](https://laravel.com/docs/12.x/eloquent), Laravel’s ORM (Object-Relational Mapper).

**Important**: In LBAW projects **we do not use Laravel migrations** to create tables.
Instead, the schema is defined in raw SQL (see `database/thingy-seed.sql`), and we use Eloquent **only for querying and relationships**.

Here is an example of Eloquent's query building syntax:

```php
$card = Card::findOrFail($id);
```

This line tells Eloquent to fetch a card from the database with a certain `id` (the primary key of the table).
The result will be an object of the class `Card` defined in `app/Models/Card.php`.


#### Disabling timestamps

By default, Eloquent expects every table to have `created_at` and `updated_at` timestamp columns.
Since the provided schema does not use them, you must explicitly disable timestamps in each model:

```php
class Card extends Model
{
    public $timestamps = false;
}
```

This prevents Laravel from trying to insert or update non-existent timestamp columns.


#### Defining relationships

Eloquent models also describe how tables relate to each other.

For example, the Card model defines:

```php
/**
 * Get the user that owns the card
 */
public function user(): BelongsTo
{
    return $this->belongsTo(User::class);
}

/**
 * Get the items for the card
 */
public function items(): HasMany
{
    return $this->hasMany(Item::class)->orderBy('id');
}
```

This tells Eloquent:

* A `Card` belongs to a single User (`user_id` foreign key).
* A `Card` has many `Items`, ordered by their `id`.

With these relationships defined, you can load related data easily:

```php
$card = Card::with('items')->findOrFail($id);
```


### 4) Policies

[Policies](https://laravel.com/docs/12.x/authorization#writing-policies) define which actions a user is authorized to perform on a given resource (e.g., a card or an item).
They are stored in the `app/Policies` folder and are typically created with:

```bash
php artisan make:policy CardPolicy --model=Card
```

This generates a class `CardPolicy` where you can define methods such as `view`, `create`, `update`, or `delete`.


For example, in the `CardPolicy.php` file we defined a `view` method that only allows a certain user to view a card if that user is the card owner:

```php
/**
 * Determine if the given card can be viewed by the user.
 */
public function view(User $user, Card $card): bool
{
    // Only the card owner can view it
    return $user->id === $card->user_id;
}
```

In this example:

* `$user` is the authenticated user (automatically passed by Laravel).
* `$card` is the `Card` model instance retrieved from the database.
* `user_id` is the foreign key column in the `cards` table that links the card to its owner.


#### Using the policy in a controller

Inside a controller you can enforce this policy with:

```php
$this->authorize('view', $card);
```

Alternatively, you can use the `Gate` facade:

```php
Gate::authorize('view', $card);
```

Both throw a **403 Forbidden** error if the user is not authorized.

Notice that you don’t need to pass the current user — Laravel handles that automatically.

If you follow the expected naming convention (`CardPolicy` for the `Card` model, `ItemPolicy` for the `Item` model, etc.), Laravel will [auto-discover the policies](https://laravel.com/docs/12.x/authorization#policy-auto-discovery).

If you don’t follow the convention, you will need to manually register the policies ([see the documentation](https://laravel.com/docs/12.x/authorization#registering-policies)).


### 5) Views

A controller only needs to return HTML code for it to be sent to the browser.
In Laravel, we typically use [Blade](https://laravel.com/docs/12.x/blade), Laravel’s templating engine, to simplify and organize views.

Example of returning a view from a controller:

```php
return view('pages.card', ['card' => $card]);
```

In this example:

* `pages.card` refers to a Blade template at `resources/views/pages/card.blade.php`
* The second parameter (`['card' => $card]`) is an **array of data** passed into the view. Inside the Blade file, this data is available as the variable `$card`.


#### Template inheritance

Blade supports template inheritance. For example:

```php
@extends('layouts.app')
```

This tells Laravel that the template extends a **base layout**, usually found at `resources/views/layouts/app.blade.php`.

In that base layout, sections from child templates are inserted using directives like:

```php
@yield('content')
```

Any child view that defines a `@section('content') ... @endsection` block will have its content inserted into this spot.


#### Organizing templates

To keep templates manageable, we use different folders:

* `layouts/` -- Base templates (e.g., `app.blade.php`)
* `pages/` -- Full-page templates (e.g., `card.blade.php`, `cards.blade.php`)
* `partials/` -- Reusable snippets of HTML (e.g., `card.blade.php` for one card, `item.blade.php` for one item)

This organization keeps code **DRY** (Don’t Repeat Yourself) and encourages reuse of common UI pieces.


### 6) CSS

Laravel does not enforce a specific way to manage CSS.
In this template, the simplest approach is used: plain CSS files placed under the `public/css` directory.

* The main stylesheet is `public/css/app.css`.
* You can add additional CSS files (e.g., `cards.css`, `auth.css`) if you want to organize styles by feature.

All CSS files in `public/` are publicly accessible, so you can reference them from your layout file:

```html
<link href="{{ asset('css/app.css') }}" rel="stylesheet">
```

For advanced projects, you might explore tools like [Vite](https://laravel.com/docs/12.x/vite) for asset bundling, but that is not required here.


### 7) JavaScript

Similarly, JavaScript files are placed in the `public/js` directory.
The main script for this project is `public/js/app.js`.

This file contains all the logic needed for interacting with the **Thingy!** application (creating/deleting cards and items dynamically using Ajax).

Scripts are included in the layout file, typically with:

```html
<script src="{{ asset('js/app.js') }}" defer></script>
```

Using the defer attribute ensures the script runs after the DOM is loaded.

You can split logic into multiple files if needed (`cards.js`, `auth.js`, etc.), but in this template everything lives in `app.js` for simplicity.



### 8) Configuration

Laravel applications rely on **environment variables** for configuration.
These variables are read when the Laravel process starts and are usually defined in one of two places:

* The **system environment** (variables exported before Laravel runs)
* The `.env` file in the project root (most common during development)

The `.env` file overrides the current environment and is where you should configure things like database credentials (prefixed with `DB_`).

#### Environment files in this project

* `.env` -- Used for local development
* `.env.production` -- Packaged inside the Docker image, points to the **production database**

**Important**: For LBAW, you must manually create a database schema that matches your group’s username (e.g., `lbawYYXX`).

Note that you can use the remote database locally by updating your `.env` file accordingly.


#### Updating configuration

Laravel caches configuration and routes for performance.
If you change environment variables or config files, clear these caches:

```bash
php artisan route:clear
php artisan cache:clear
php artisan config:clear
```

This ensures your changes take effect without restarting the development server.


## Publishing your image

To deploy your project, you must create a **Docker image** using the [Dockerfile](Dockerfile) in your repository.
This image contains your Laravel application and all its dependencies, and will be published to **GitLab’s Container Registry** for deployment and evaluation.

You need to have Docker installed and properly configured to build and publish images.

**Note**: The provided script builds **multi-platform images** (for both AMD64 and ARM64).

You should **keep your git main branch functional** and regularly deploy your code as a Docker image.
This image will be used to test and evaluate your project.


### Configure environment for production

Before building your Docker image, configure your `.env.production` file with your group's `db.fe.up.pt` credentials:

```bash
DB_CONNECTION=pgsql
DB_HOST=db.fe.up.pt
DB_PORT=5432
DB_SCHEMA=lbawYYXX
DB_DATABASE=lbawYYXX
DB_USERNAME=lbawYYXX
DB_PASSWORD=password
```

**Important**: `.env.production` will be copied inside the Docker image — it must be correct for your container to connect to the database.


### Publishing steps

1. Login to GitLab's Container Registry (requires FEUP VPN/network):

```bash
docker login gitlab.up.pt:5050
# Username is upXXXXX@up.pt
```

2. Edit `upload_image.sh` and set your group’s image name:

```bash
IMAGE_NAME=gitlab.up.pt:5050/lbaw/lbawYYYY/lbawYYXX # Replace with your group's image name
```

3. Build and upload from the project's root:

```bash
./upload_image.sh
```

Only **one image per group** should exist. Any member can update it after logging in.


## Testing your image locally

After publishing, you can run your image locally to test it:

```bash
docker run -d --name lbawYYXX -p 8001:80 gitlab.up.pt:5050/lbaw/lbawYYYY/lbawYYXX
```

This command:

* Starts a container named `lbawYYXX` from your published image
* Runs it in the background (`-d`)
* Maps **port 8001** on your machine to **port 80** inside the container
* Makes the app available at: `http://localhost:8001`


### Inspecting the container

While running your container, you can use another terminal to run a shell inside the container:

```bash
docker exec -it lbawYYXX bash
```

Inside the container you may, for example, see the content of the web server logs:

```bash
# Follow error logs
root@2804d54698c0:/# tail -f /var/log/nginx/error.log

# Follow access logs
root@2804d54698c0:/# tail -f /var/log/nginx/access.log
```


### Stopping the container

To stop and remove the container:

```bash
docker stop lbawYYXX
docker rm lbawYYXX
```


## Automated Tests

The template is configured to run automated tests using [Laravel’s built-in PHPUnit framework](https://laravel.com/docs/12.x/testing).

Tests run against a dedicated schema (`thingy_test`) using the same raw SQL seed file (`database/thingy-seed.sql`) as development.

### Running tests

Run all tests with:

```bash
php artisan test
```

This will:

* Load configuration from `.env.testing`
* Seed the `thingy_test` schema once at the start (using `DatabaseSeeder`)
* Run all test classes under `tests/`


### Example feature test

The template includes a feature test for cards in `tests/Feature/CardTest.php`:

```php
public function test_guest_is_redirected_when_accessing_cards(): void
{
    $response = $this->get('/cards');

    $response->assertStatus(302);        // guest is redirected
    $response->assertRedirect('/login'); // to login page
}
```

```php
public function test_authenticated_user_can_create_card(): void
{
    $user = User::firstOrFail(); // seeded demo user

    $response = $this->actingAs($user)->postJson('/api/cards', [
        'name' => 'My First Test Card',
    ]);

    $response->assertStatus(200);
    $this->assertDatabaseHas('cards', [
        'name' => 'My First Test Card',
        'user_id' => $user->id,
    ]);
}
```

Notes:

* Tests use an **isolated schema** (`thingy_test`) so they don’t interfere with your development data.
* Add new tests under `tests/Feature/` for HTTP endpoints, or `tests/Unit/` for isolated class logic.


---
-- LBAW, 2025
