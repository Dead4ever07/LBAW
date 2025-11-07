# Making of Template Laravel (aka Thingy!)

This document describes how to set up **Template Laravel**, which showcases the **Thingy!** web application, from scratch.  
It is intended as a guide for students to understand how the provided Laravel Template skeleton was built.


## Requirements

Before starting, ensure you have the following installed:

- [PHP](https://www.php.net/) (version 8.3 or higher recommended)  
- [Composer](https://getcomposer.org/) (version 2.2 or higher recommended)

We recommend Ubuntu 24.04 (or newer). On macOS you can use [Homebrew](https://brew.sh/), and on Windows we suggest [WSL with Ubuntu](https://learn.microsoft.com/en-us/windows/wsl/install).


## 1. Start a Laravel project

Check the latest official installation instructions here:  
https://laravel.com/docs/12.x/installation

Create a fresh Laravel project:

```bash
composer create-project laravel/laravel template-laravel
```

This creates a new Laravel project in a folder called `template-laravel`.


## 2. Setup PostgreSQL and pgAdmin with Docker

We will run PostgreSQL and pgAdmin in Docker containers.  

1. Copy the provided `docker-compose.yaml` file into your project root.  
2. Start the containers:

```bash
docker compose up -d
```

3. Open your browser and navigate to `http://localhost:4321` to access pgAdmin4.  

Inside pgAdmin, add a new server connection with these credentials:

- **hostname**: `postgres`  
- **username**: `postgres`  
- **password**: `password`

Note: use `postgres` (the service name in Docker Compose) instead of `localhost`, because containers communicate via Docker’s internal network.


## 3. Database setup

The application includes an SQL file (`thingy-seed.sql`) with schema and seed data.

1. Copy `thingy-seed.sql` to your `database` folder.

2. Update `config/database.php` so that Laravel supports the `DB_SCHEMA` environment variable:

```php
'search_path' => env('DB_SCHEMA', 'public'),
```

This ensures Laravel uses the schema defined in `.env`, or defaults to `public`.

3. Update your `.env` file:

```bash
APP_NAME=Thingy

DB_CONNECTION=pgsql
DB_HOST=localhost
DB_PORT=5432
DB_SCHEMA=thingy
DB_DATABASE=postgres
DB_USERNAME=postgres
DB_PASSWORD=password

CACHE_STORE=file
SESSION_DRIVER=file
```

4. Update the database seeder (`database/seeders/DatabaseSeeder.php`) to load the SQL file:

```php
<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $path = base_path('database/thingy-seed.sql');
        $sql = file_get_contents($path);
        DB::unprepared($sql);
        $this->command->info('Database seeded!');
    }
}
```

Note: This is the minimal version, enough to get you started. For a more flexible multi-environment setup (development + testing, schema overrides, etc.), see [Section 12. Define Laravel Tests](#12-define-laravel-tests).

5. Seed the database:

```bash
php artisan db:seed
```


## 4. Define Laravel Models

Laravel models provide an **object-oriented interface** to database tables.
Relationships allow intuitive queries.

### Card model

```bash
php artisan make:model Card
```

Changes in `app/Models/Card.php`:

- Disable automatic timestamps (our DB does not have created_at/updated_at fields):

```php
public $timestamps = false;
```

- Define relationships:

```php
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

public function user(): BelongsTo
{
    return $this->belongsTo(User::class);
}

public function items(): HasMany
{
    return $this->hasMany(Item::class)->orderBy('id');
}
```


### Item model

```bash
php artisan make:model Item
```

- Disable automatic timestamps:

```php
public $timestamps = false;
```

- Define relationship:

```php
public function card(): BelongsTo
{
    return $this->belongsTo(Card::class);
}
```


### User model

Update the existing `User` model:

- Disable timestamps:

```php
public $timestamps = false;
```

- Add relationship:

```php
public function cards(): HasMany
{
    return $this->hasMany(Card::class);
}
```


### Test with Tinker

Tinker is Laravel’s REPL for testing code:

```bash
php artisan tinker
```

Inside Tinker:

```php
use App\Models\Card;
Card::all();
```


## 5. Define Laravel Controllers

Controllers connect **routes** (HTTP requests) with **models and views**.


Generate controllers:

```bash
php artisan make:controller CardController
php artisan make:controller ItemController
```

Edit `app/Http/Controllers/CardController.php` and `ItemController.php` with logic for viewing, creating, updating, and deleting cards and items.


## 6. Use Laravel Manual Authentication

Instead of using a starter kit, this project implements **manual authentication**.
This approach gives you **more control** and helps you understand how authentication works under the hood.

If you want a faster setup in real projects, Laravel provides **quickstarter packages** such as [Breeze](https://laravel.com/docs/12.x/starter-kits#laravel-breeze) or [Jetstream](https://jetstream.laravel.com/) that generate authentication scaffolding automatically.

Generate controllers:

```bash
php artisan make:controller Auth/LoginController
php artisan make:controller Auth/RegisterController
php artisan make:controller Auth/LogoutController
```

Edit:

- `app/Http/Controllers/Auth/LoginController.php` → handle login and sessions  
- `app/Http/Controllers/Auth/RegisterController.php` → handle registration  
- `app/Http/Controllers/Auth/LogoutController.php` → handle logout  

Reference: https://laravel.com/docs/12.x/authentication#authenticating-users


## 7. Define Laravel Policies

Policies enforce **authorization** (who can do what).

Generate policies:

```bash
php artisan make:policy CardPolicy --model=Card
php artisan make:policy ItemPolicy --model=Item
```

Edit:

- `app/Policies/CardPolicy.php` → restrict card access to owners  
- `app/Policies/ItemPolicy.php` → restrict item access to card owners  

Policies ensure users cannot access or modify resources they don’t own.


## 8. Define Laravel Routes

Routes define the mapping from URL → Controller → Action.

Edit `routes/web.php` to define routes for:

- Authentication (login, register, logout)  
- Cards (index, show, create, delete)  
- Items (create, update, delete)  

Example:

```php
Route::get('cards/{card}', [CardController::class, 'show'])->name('cards.show');
```


## 9. Define Laravel Blade Views

Blade is Laravel’s templating system.

Generate views:

```bash
php artisan make:view auth.login
php artisan make:view auth.register
php artisan make:view layouts.app
php artisan make:view pages.card
php artisan make:view pages.cards
php artisan make:view partials.card
php artisan make:view partials.item
```

Organize them into:

- `layouts` → base HTML layouts  
- `pages` → full-page templates  
- `partials` → reusable snippets (cards, items)


## 10. Define Static CSS

Static files live under `public/`.

Place styles in:

- `public/css/app.css` → your application styles  
- `public/css/milligram.css` → a lightweight CSS framework  

Link them in `layouts/app.blade.php`.


## 11. Define Static JavaScript

Create:

- `public/js/app.js`

This file will handle:

- Ajax requests for creating/updating/deleting cards and items  
- DOM manipulation for dynamically updating the interface


## 12. Define Laravel Tests

To support Laravel automated tests, we extended the setup so that development and testing share the same seeding logic.

### Update DatabaseSeeder.php for multi-environment support

We modified `DatabaseSeeder.php` so it can seed both **development** and **testing** databases.
The SQL script reads `current_setting('app.schema', true)` and falls back to thingy if no override is provided. In Laravel, we set this variable using `set_config()` before running the SQL file.

```php
public function run(): void
{
    // Get schema name from environment (e.g., .env or .env.testing)
    $schema = env('DB_SCHEMA');

    // Load the raw SQL file
    $path = base_path('database/thingy-seed.sql');
    $sql = file_get_contents($path);

    // If DB_SCHEMA is set, expose it to the SQL script
    // (the script reads it via current_setting('app.schema', true))
    if ($schema !== null) {
        DB::statement("SELECT set_config('app.schema', ?, false)", [$schema]);
    }

    // Run the SQL script
    DB::unprepared($sql);

    // Show a message in the Artisan console
    $this->command?->info('Database seeded using schema: ' . ($schema ?? 'thingy (default)'));
}
```


### Update phpunit.xml

We added a comment in phpunit.xml to clarify DB settings:

```xml
<!-- DB_* settings are loaded from .env.testing -->
<!-- Add schema if you want to enforce it here -->
<!-- <env name="DB_SCHEMA" value="thingy_test"/> -->
```

This way, the test environment always uses `.env.testing`, but developers can override in `phpunit.xml` if needed.


### Disable migrations

Because we are not using Laravel migrations (we seed from raw SQL), we disabled `migrate:fresh` during tests.
Instead, tests only run the seeder (DatabaseSeeder) once per process.

```php
abstract class TestCase extends BaseTestCase
{
    /** Seed only once per test process. */
    private static bool $seeded = false;

    protected function setUp(): void
    {
        parent::setUp();

        if (! self::$seeded) {
            // Runs DatabaseSeeder, which loads database/thingy-seed.sql
            // and swaps {{schema}} with DB_SCHEMA from .env.testing
            $this->seed();

            self::$seeded = true;
        }
    }
}
```

### Create a Testing Environment

Create `.env.testing`:

```bash
APP_NAME=Thingy
APP_ENV=local
APP_KEY=base64:xWdLc4KY3iJKHCupluHuu1nDwvprk4OAqnsc6RRrGsA=
APP_DEBUG=true
APP_URL=http://localhost:8000

LOG_CHANNEL=stack
LOG_LEVEL=debug

DB_CONNECTION=pgsql
DB_HOST=localhost
DB_PORT=5432
DB_SCHEMA=thingy_test
DB_DATABASE=postgres
DB_USERNAME=postgres
DB_PASSWORD=password

BROADCAST_DRIVER=log
CACHE_STORE=file
SESSION_DRIVER=file
SESSION_LIFETIME=120
QUEUE_CONNECTION=sync
```

### Writing Tests

Generate a feature test:

```bash
php artisan make:test CardTest
```

Edit `tests/Feature/CardTest.php` accordingly to test guest redirection, card creation, and deletion.

```php
public function test_authenticated_user_can_create_card(): void
{
    // Grab the demo user from the seed (John Doe)
    $user = User::firstOrFail();

    // Act as this user and create a card
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

#### Note on fillable attributes

Laravel protects against mass assignment by default.

If you want to use `Card::create([...])` in your tests, you must explicitly define which attributes can be mass-assigned in your model:

```php
class Card extends Model
{
    public $timestamps = false;

    protected $fillable = ['name', 'user_id'];

    // relationships ...
}
```

Without this, calling `Card::create()` in tests will throw a `MassAssignmentException`.


# Conclusion

Following these steps, we built the **Thingy!** Laravel template from scratch:

1. Installed Laravel  
2. Configured PostgreSQL and pgAdmin with Docker  
3. Set up database schema and seeding  
4. Defined models, controllers, and policies  
5. Added authentication  
6. Implemented Blade templates, CSS, and JS  
