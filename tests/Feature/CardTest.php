<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Card;

class CardTest extends TestCase
{
    /**
     * Guests are redirected to login when hitting /cards.
     */
    public function test_guest_is_redirected_when_accessing_cards(): void
    {
        $response = $this->get('/cards');

        $response->assertStatus(302); // 302 = redirect
        $response->assertRedirect('/login'); // Laravel sends to login page
    }

    /**
     * Authenticated user can create a card via AJAX endpoint.
     */
    public function test_authenticated_user_can_create_card(): void
    {
        // Grab the demo user from the seed (John Doe)
        $user = User::firstOrFail();

        // Act as this user and send a request to create a card
        $response = $this->actingAs($user)->postJson('/api/cards', [
            'name' => 'My First Test Card',
        ]);

        // The API should return success (200 = ok)
        $response->assertStatus(200);

        // Check that the card is really in the database
        $this->assertDatabaseHas('cards', [
            'name' => 'My First Test Card',
            'user_id' => $user->id,
        ]);
    }

    /**
     * Authenticated user can delete a card via AJAX endpoint.
     */
    public function test_authenticated_user_can_delete_card(): void
    {
        // Grab the demo user from the seed (John Doe)
        $user = User::firstOrFail();

        // Insert a temp card owned by this user
        $card = Card::create([
            'name' => 'Temp card',
            'user_id' => $user->id,
        ]);

        // Act as this user and delete the card
        $response = $this->actingAs($user)->deleteJson("/api/cards/{$card->id}");

        // API should return success (200 = OK)
        $response->assertStatus(200);

        // Check that the card was removed from the database
        $this->assertDatabaseMissing('cards', [
            'id' => $card->id,
        ]);
    }
}
