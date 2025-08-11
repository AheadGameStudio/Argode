// Language switcher functionality
document.addEventListener('DOMContentLoaded', function() {
    // Add language switcher to navigation
    addLanguageSwitcher();
});

function addLanguageSwitcher() {
    // Find the header navigation
    const nav = document.querySelector('.md-header__inner .md-header__title');
    if (!nav) return;

    // Create language switcher container
    const langSwitcher = document.createElement('div');
    langSwitcher.className = 'language-switcher';
    langSwitcher.style.marginLeft = 'auto';

    // Create select element
    const select = document.createElement('select');
    select.style.marginLeft = '1rem';
    
    // Get current path to determine language
    const currentPath = window.location.pathname;
    const isJapanese = currentPath.includes('/ja/');
    
    // Add language options
    const enOption = document.createElement('option');
    enOption.value = 'en';
    enOption.text = 'English';
    enOption.selected = !isJapanese;
    
    const jaOption = document.createElement('option');
    jaOption.value = 'ja';
    jaOption.text = '日本語';
    jaOption.selected = isJapanese;
    
    select.appendChild(enOption);
    select.appendChild(jaOption);
    
    // Add change event listener
    select.addEventListener('change', function() {
        const selectedLang = this.value;
        let newPath = '';
        
        if (selectedLang === 'ja') {
            if (isJapanese) {
                return; // Already on Japanese
            }
            // Switch to Japanese
            if (currentPath === '/' || currentPath === '/Argode/') {
                newPath = '/Argode/ja/';
            } else {
                newPath = currentPath.replace('/Argode/', '/Argode/ja/');
            }
        } else {
            if (!isJapanese) {
                return; // Already on English
            }
            // Switch to English
            newPath = currentPath.replace('/ja/', '/');
        }
        
        // Navigate to new language
        window.location.href = newPath;
    });
    
    langSwitcher.appendChild(select);
    
    // Insert the language switcher
    const headerTitle = document.querySelector('.md-header__title');
    if (headerTitle) {
        headerTitle.parentNode.insertBefore(langSwitcher, headerTitle.nextSibling);
    }
}

// Theme switcher enhancement
document.addEventListener('DOMContentLoaded', function() {
    // Enhance existing theme toggle with better accessibility
    const themeToggle = document.querySelector('[data-md-toggle="__palette"]');
    if (themeToggle) {
        themeToggle.setAttribute('aria-label', 'Switch color scheme');
        themeToggle.setAttribute('title', 'Toggle dark/light mode');
    }
});
