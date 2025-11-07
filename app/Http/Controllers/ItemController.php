<?php

namespace App\Http\Controllers;

use App\Models\Card;
use App\Models\Item;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class ItemController extends Controller
{
    /**
     * Creates a new item for the given card.
     */
    public function store(Request $request, Card $card)
    {
        // Prepare a new Item instance already tied to the given Card.
        // Using make() (instead of create()) builds the object in memory
        // without saving it yet, so we can authorize before persisting.
        $item = $card->items()->make([
            'description' => $request->input('description'),
            'done' => false,
        ]);

        // Ensure the current user is authorized to create this specific item.
        Gate::authorize('create', $item);

        // Persist the item and return it as JSON for the frontend.
        $item->save();
        return response()->json($item);
    }


    /**
     * Updates the "done" state of a specific item.
     */
    public function update(Request $request, Item $item)
    {
        // Ensure the current user is authorized to update this item.
        Gate::authorize('update', $item);

        // Apply the requested state change.
        // We only update the "done" flag here, based on the request payload.
        $item->done = $request->input('done');

        // Persist changes and return the updated item as JSON for the frontend.
        $item->save();
        return response()->json($item);
    }

    /**
     * Deletes a specific item.
     */
    public function destroy(Item $item)
    {
        // Ensure the current user is authorized to delete this item.
        Gate::authorize('delete', $item);

        // Remove the item from the database.
        $item->delete();

        // Return the deleted item as JSON so the frontend can update its state.
        return response()->json($item);
    }
}
