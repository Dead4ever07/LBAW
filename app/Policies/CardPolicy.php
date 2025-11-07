<?php

namespace App\Policies;

use App\Models\User;
use App\Models\Card;

use Illuminate\Support\Facades\Auth;

class CardPolicy
{
    /**
     * Determine whether the given user can view a specific card.
     *
     * @param  \App\Models\User  $user  The authenticated user
     * @param  \App\Models\Card  $card  The card being accessed
     * @return bool
     */
    public function view(User $user, Card $card): bool
    {
        // A card can only be viewed by its owner.
        return $user->id === $card->user_id;
    }

    /**
     * Determine whether the given user can view any cards.
     *
     * @param  \App\Models\User  $user
     * @return bool
     */
    public function viewAny(User $user): bool
    {
        // Any authenticated user can view their own cards.
        return Auth::check();
    }

    /**
     * Determine whether the given user can create new cards.
     *
     * @param  \App\Models\User  $user
     * @return bool
     */
    public function create(User $user): bool
    {
        // Any authenticated user can create a card.
        return Auth::check();
    }

    /**
     * Determine whether the given user can delete a specific card.
     *
     * @param  \App\Models\User  $user  The authenticated user
     * @param  \App\Models\Card  $card  The card being deleted
     * @return bool
     */
    public function delete(User $user, Card $card): bool
    {
        // A card can only be deleted by its owner.
      return $user->id === $card->user_id;
    }
}
