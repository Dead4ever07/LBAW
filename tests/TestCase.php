<?php

namespace Tests;

use Illuminate\Foundation\Testing\TestCase as BaseTestCase;

abstract class TestCase extends BaseTestCase
{
    /** Seed only once per test process. */
    private static bool $seeded = false;

    protected function setUp(): void
    {
        parent::setUp();

        if (! self::$seeded) {
            // Runs DatabaseSeeder, which loads database/thingy-seed.sql
            // and uses DB_SCHEMA from .env.testing via set_config('app.schema', ...)
            $this->seed();

            self::$seeded = true;
        }
    }
}