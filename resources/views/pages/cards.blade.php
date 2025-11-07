@extends('layouts.app')

@section('content')
<section id="cards">
    {{-- Render each card using the partial --}}
    @each('partials.card', $cards, 'card')

    {{-- Form for creating a new card --}}
    <article class="card">
        <form class="new_card">
            <input type="text" name="name" placeholder="new card">
        </form>
    </article>
</section>

@endsection