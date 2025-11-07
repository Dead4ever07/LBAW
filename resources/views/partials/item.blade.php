<li class="item" data-id="{{$item->id}}">
    <label>
        {{-- Checkbox reflects whether the item is done --}}
        <input type="checkbox" @checked($item->done)>

        {{-- Item description --}}
        <span>{{ $item->description }}</span>

        {{-- Delete button (handled via JS) --}}
        <a href="#" class="delete">&#10761;</a>
    </label>
</li>