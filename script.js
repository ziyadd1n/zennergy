'use strict';
const menuToggle = document.querySelector('.menu-toggle');
const navigation = document.querySelector('#main-nav');
function closeMenu() { navigation.classList.remove('open'); menuToggle.setAttribute('aria-expanded', 'false'); }
menuToggle.addEventListener('click', () => {
  const open = navigation.classList.toggle('open');
  menuToggle.setAttribute('aria-expanded', String(open));
});
navigation.querySelectorAll('a').forEach(link => link.addEventListener('click', closeMenu));
document.addEventListener('keydown', event => { if (event.key === 'Escape' && navigation.classList.contains('open')) { closeMenu(); menuToggle.focus(); } });
const filterButtons = [...document.querySelectorAll('[data-filter]')];
const articles = [...document.querySelectorAll('.article')];
const search = document.querySelector('#search');
let activeFilter = 'all';
function filterArticles() {
  const query = search.value.toLowerCase().trim();
  let count = 0;
  articles.forEach(article => {
    const matches = (activeFilter === 'all' || article.dataset.category.split(' ').includes(activeFilter)) && article.textContent.toLowerCase().includes(query);
    article.hidden = !matches;
    if (matches) count++;
  });
  document.querySelector('#no-results').hidden = count !== 0;
  document.querySelector('#results-status').textContent = count + ' selected ' + (count === 1 ? 'story or resource' : 'stories and resources') + ' · External sources, with original ZEN energy summaries.';
}
function setFilter(topic) {
  activeFilter = topic;
  filterButtons.forEach(button => {
    const selected = button.dataset.filter === topic;
    button.classList.toggle('active', selected);
    button.setAttribute('aria-pressed', String(selected));
  });
  filterArticles();
}
filterButtons.forEach(button => button.addEventListener('click', () => setFilter(button.dataset.filter)));
search.addEventListener('input', filterArticles);
document.querySelectorAll('[data-topic]').forEach(link => link.addEventListener('click', () => { search.value = ''; setFilter(link.dataset.topic); }));
document.querySelector('#year').textContent = new Date().getFullYear();
const privacyDialog = document.querySelector('#privacy-dialog');
document.querySelector('#privacy-open').addEventListener('click', () => privacyDialog.showModal());
document.querySelector('#privacy-close').addEventListener('click', () => privacyDialog.close());
privacyDialog.addEventListener('click', event => { if (event.target === privacyDialog) { const rect = privacyDialog.getBoundingClientRect(); if (event.clientX < rect.left || event.clientX > rect.right || event.clientY < rect.top || event.clientY > rect.bottom) privacyDialog.close(); } });

filterArticles();

