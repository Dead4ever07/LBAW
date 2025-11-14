<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class DatabaseSeeder extends Seeder
{
    /**
     * Runs database/thingy-seed.sql as-is.
     * The SQL reads current_setting('app.schema', true) and defaults to 'thingy'.
     */
    public function run(): void
    {
        // Get schema name from environment (e.g., .env or .env.testing)
        $schema = env('DB_SCHEMA');

        // Load the raw SQL file
        $path = base_path('database/schema.sql');
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
}
