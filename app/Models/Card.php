<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

// Import Eloquent relationship classes.
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Card extends Model
{
    // Disable default created_at and updated_at timestamps for this model.
    public $timestamps = false;

    /**
     * The attributes that are mass assignable.
     *
     * Only these fields may be filled using methods like create() or update().
     * This protects against mass-assignment vulnerabilities.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'user_id',
    ];

    /**
     * Get the user who owns this card.
     *
     * Defines a many-to-one relationship:
     * a card belongs to exactly one user.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get all items belonging to this card.
     *
     * Defines a one-to-many relationship:
     * a card can have many items. Items are always
     * returned ordered by their ID for consistent display.
     */
    public function items(): HasMany
    {
        return $this->hasMany(Item::class)->orderBy('id');
    }
}
