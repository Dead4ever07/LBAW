@extends('layouts.app')

@section('title', $card->name . ' | ' . config('app.name'))

@section('content')
    <section id="cards">
        {{-- Render a single card using the partial --}}
        @include('partials.card', ['card' => $card])
    </section>
@endsection