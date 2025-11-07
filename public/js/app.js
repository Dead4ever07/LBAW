/**
 * Attach all event listeners to existing DOM elements.
 * Called once when the page loads.
 */
function addEventListeners() {
  // When an item checkbox is toggled, send an update request
  document.querySelectorAll('article.card li.item input[type=checkbox]')
    .forEach(cb => cb.addEventListener('change', sendItemUpdateRequest));

  // When an item form is submitted, create a new item
  document.querySelectorAll('article.card form.new_item')
    .forEach(form => form.addEventListener('submit', sendCreateItemRequest));

  // When an item delete link is clicked, delete the item
  document.querySelectorAll('article.card li a.delete')
    .forEach(link => link.addEventListener('click', sendDeleteItemRequest));

  // When a card delete link is clicked, delete the card
  document.querySelectorAll('article.card header a.delete')
    .forEach(link => link.addEventListener('click', sendDeleteCardRequest));

  // Attach event listener for creating new cards (if the form exists)
  const cardCreator = document.querySelector('article.card form.new_card');
  if (cardCreator) {
    cardCreator.addEventListener('submit', sendCreateCardRequest);
  }
}
  
/**
 * Encode a data object into URL-encoded form data.
 * Example: {a: 1, b: 2} → "a=1&b=2"
 */
function encodeForAjax(data) {
  return data ? new URLSearchParams(data).toString() : null;
}
  
/**
 * Send an AJAX request using the Fetch API.
 * Handles CSRF tokens and common headers.
 */
async function sendAjaxRequest(method, url, data, handler) {
  try {
    const response = await fetch(url, {
      method,
      headers: {
        'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: data ? encodeForAjax(data) : null,
    });

    if (!response.ok) {
      // If the server returns an error, refresh the page as fallback
      window.location = '/';
      return;
    }

    // Parse JSON response and pass it to the handler
    const json = await response.json();
    handler(json);
  } catch (err) {
    console.error('Request failed:', err);
    window.location = '/';
  }
}
  
/**
 * Update the 'done' status of an item when its checkbox is toggled.
 */
function sendItemUpdateRequest() {
  const item = this.closest('li.item');
  const id = item.dataset.id;
  const checked = this.checked;

  sendAjaxRequest('PATCH', `/api/items/${id}`, { done: checked }, itemUpdatedHandler);
}
  

/**
 * Delete an item when the delete link is clicked.
 */
function sendDeleteItemRequest(event) {
  event.preventDefault();
  const id = this.closest('li.item').dataset.id;
  sendAjaxRequest('DELETE', `/api/items/${id}`, null, itemDeletedHandler);
}
  
/**
 * Create a new item inside a card when the form is submitted.
 */
function sendCreateItemRequest(event) {
  event.preventDefault();
  const cardId = this.closest('article').dataset.id;
  const description = this.querySelector('input[name=description]').value.trim();

  if (description) {
    sendAjaxRequest('POST', `/api/cards/${cardId}/items`, { description }, itemAddedHandler);
  }
}
  
/**
 * Delete a card when the delete link in its header is clicked.
 */
function sendDeleteCardRequest(event) {
  event.preventDefault();
  const id = this.closest('article').dataset.id;
  sendAjaxRequest('DELETE', `/api/cards/${id}`, null, cardDeletedHandler);
}
  
/**
 * Create a new card when the new card form is submitted.
 */
function sendCreateCardRequest(event) {
  event.preventDefault();
  const name = this.querySelector('input[name=name]').value.trim();

  if (name) {
    sendAjaxRequest('POST', '/api/cards', { name }, cardAddedHandler);
  }
}
  
/**
 * Handler: update checkbox state after server confirms change.
 */
function itemUpdatedHandler(item) {
  const checkbox = document.querySelector(`li.item[data-id="${item.id}"] input[type=checkbox]`);
  if (checkbox) checkbox.checked = item.done === "true";
}
  
/**
 * Handler: add a new item to the DOM after server creates it.
 */
function itemAddedHandler(item) {
  const newItem = createItem(item);
  const card = document.querySelector(`article.card[data-id="${item.card_id}"]`);
  const form = card.querySelector('form.new_item');

  // Insert the new item before the form
  form.previousElementSibling.append(newItem);

  // Reset the input field
  form.querySelector('[type=text]').value = "";
}
  
/**
 * Handler: remove the deleted item from the DOM.
 */
function itemDeletedHandler(item) {
  document.querySelector(`li.item[data-id="${item.id}"]`)?.remove();
}
  
/**
 * Handler: remove the deleted card from the DOM.
 */
function cardDeletedHandler(card) {
  document.querySelector(`article.card[data-id="${card.id}"]`)?.remove();
}
  
/**
 * Handler: add a new card to the DOM after server creates it.
 */
function cardAddedHandler(card) {
  const newCard = createCard(card);

  // Reset the "new card" form
  const form = document.querySelector('article.card form.new_card');
  form.querySelector('[type=text]').value = "";

  // Insert new card before the "new card" placeholder
  const placeholder = form.parentElement;
  placeholder.parentElement.insertBefore(newCard, placeholder);

  // Focus on adding an item inside the new card
  newCard.querySelector('[type=text]').focus();
}
  
/**
 * Create a new <article> element representing a card.
 * Includes its header, item list, and "add item" form.
 */
function createCard(card) {
  const article = document.createElement('article');
  article.className = 'card';
  article.dataset.id = card.id;
  article.innerHTML = `
    <header>
      <h2><a href="cards/${card.id}">${card.name}</a></h2>
      <a href="#" class="delete">&#10761;</a>
    </header>
    <ul></ul>
    <form class="new_item">
      <input name="description" type="text">
    </form>
  `;

  // Attach event listeners to its internal form and delete link
  article.querySelector('form.new_item')
    .addEventListener('submit', sendCreateItemRequest);

  article.querySelector('header a.delete')
    .addEventListener('click', sendDeleteCardRequest);

  return article;
}
  
/**
 * Create a new <li> element representing an item inside a card.
 */
function createItem(item) {
  const li = document.createElement('li');
  li.className = 'item';
  li.dataset.id = item.id;
  li.innerHTML = `
    <label>
      <input type="checkbox" ${item.done ? 'checked' : ''}>
      <span>${item.description}</span>
      <a href="#" class="delete">&#10761;</a>
    </label>
  `;

  // Attach event listeners to the checkbox and delete link
  li.querySelector('input').addEventListener('change', sendItemUpdateRequest);
  li.querySelector('a.delete').addEventListener('click', sendDeleteItemRequest);

  return li;
}

/**
 * Normalize checkboxes to their default state after page load
 * (fixes back/forward navigation restoring wrong state).
 */
function normalizeCheckboxesToServer() {
  document.querySelectorAll('li.item input[type=checkbox]')
    .forEach(cb => cb.checked = cb.defaultChecked);
}

// Run setup when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  normalizeCheckboxesToServer();
  addEventListeners();
});

// Also re-run normalization when restoring from bfcache (back/forward navigation)
window.addEventListener('pageshow', normalizeCheckboxesToServer);
  