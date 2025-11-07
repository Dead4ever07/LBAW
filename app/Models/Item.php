<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

// Import Eloquent relationship classes.
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Item extends Model
{
    // Disable default created_at and updated_at timestamps for this model.
    public $timestamps = false;

    /**
     * Attributes that are mass assignable.
     *
     * This allows safely using methods like create() or make()
     * with only these fields (protects against mass-assignment vulnerabilities).
     */
    protected $fillable = ['description', 'done'];

    /**
     * Get the card that this item belongs to.
     *
     * Defines an inverse one-to-many relationship:
     * each item is always associated with a single card.
     */
    public function card(): BelongsTo
    {
        return $this->belongsTo(Card::class);
    }
}
