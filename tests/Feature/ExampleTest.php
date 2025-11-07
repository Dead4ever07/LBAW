<?php

namespace Tests\Feature;

// use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ExampleTest extends TestCase
{
    /**
     * A basic test example.
     */
    public function test_the_application_returns_a_successful_response(): void
    {
        $response = $this->get('/');

        // The home route ("/") should not be directly accessible.
        // It always redirects (302) to the login page.
        $response->assertStatus(302)
                 ->assertRedirect('/login');
    }
}
