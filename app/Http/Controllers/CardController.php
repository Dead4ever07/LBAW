<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

use Illuminate\View\View;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Gate;

use App\Models\Card;

class CardController extends Controller
{
    /**
     * Display the details of a specific card.
     */
    public function show(Card $card): View
    {
        // Ensure the current user is authorized to view this card.
        Gate::authorize('view', $card);  

        // Preload the card's items, ordered by id.
        $card->load('items');

        // Render the 'pages.card' view with the card and its items.
        return view('pages.card', [
            'card' => $card
        ]);
    }

    /**
     * Display a listing of the user's cards.
     */
    public function index()
    {
        // Ensure the current user is authorized to view card listings.
        Gate::authorize('viewAny', Card::class);

        // The current user is authorized to list cards.

        // Retrieve all cards that belong to the user, ordered by id.
        $cards = Auth::user()
            ->cards()
            ->orderBy('id')
            ->get();

        // Render the 'pages.cards' view with the user's cards.
        return view('pages.cards', [
            'cards' => $cards
        ]);
    }

    /**
     * Store a newly created card in storage.
     */
    public function store(Request $request)
    {
        // Ensure the current user is authorized to create a card.
        Gate::authorize('create', Card::class);

        // Create and populate a new card instance.
        $card = new Card();
        $card->name = $request->input('name');
        $card->user_id = Auth::id();

        // Persist the card and return it as JSON.
        $card->save();
        return response()->json($card);
    }

    /**
     * Deletes a specific card.
     */
    public function destroy(Card $card)
    {
        // Ensure the current user is authorized to delete this card.
        Gate::authorize('delete', $card);

        // Delete the card and return it as JSON.
        $card->delete();
        return response()->json($card);
    }
}
