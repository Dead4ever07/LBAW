<?php

namespace App\Policies;

use App\Models\User;
use App\Models\Item;

class ItemPolicy
{
    /**
     * Determine whether the given user can create an item.
     *
     * @param  \App\Models\User  $user  The authenticated user
     * @param  \App\Models\Item  $item  The item being created
     * @return bool
     */
    public function create(User $user, Item $item): bool
    {
        // A user may only create items in cards they own.
        return $user->id === $item->card->user_id;
    }

    /**
     * Determine whether the given user can update an item.
     *
     * @param  \App\Models\User  $user  The authenticated user
     * @param  \App\Models\Item  $item  The item being updated
     * @return bool
     */
    public function update(User $user, Item $item): bool
    {
        // A user may only update items in cards they own.
        return $user->id === $item->card->user_id;
    }

    /**
     * Determine whether the given user can delete an item.
     *
     * @param  \App\Models\User  $user  The authenticated user
     * @param  \App\Models\Item  $item  The item being deleted
     * @return bool
     */
    public function delete(User $user, Item $item): bool
    {
        // A user may only delete items in cards they own.
        return $user->id === $item->card->user_id;
    }
}
