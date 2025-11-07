<article class="card" data-id="{{ $card->id }}">
    <header>
        <h2>
            {{-- Link to the card detail page --}}
            <a href="{{ route('cards.show', $card) }}">
                {{ $card->name }}
            </a>
        </h2>
        {{-- Delete button (JS handles behavior) --}}
        <a href="#" class="delete">&#10761;</a>
    </header>

    <ul>
        {{-- Render each item belonging to this card --}}
        @each('partials.item', $card->items, 'item')
    </ul>

    {{-- Inline form to create a new item for this card --}}
    <form class="new_item">
        <input type="text" name="description" placeholder="new item">
    </form>
</article>