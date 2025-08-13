# Theming Guide

Argode leverages Godot Engine's powerful built-in theming system to allow extensive customization of your visual novel's user interface, especially the AdvScreen. By creating and applying custom `Theme` resources, you can control the look and feel of every UI element without modifying core Argode code.

## Understanding Godot Themes

In Godot, a `Theme` resource is a collection of styles, fonts, colors, and icons that can be applied to `Control` nodes. When a `Control` node is part of a scene with an active `Theme`, it will automatically use the styles defined in that theme.

## Creating a Custom Theme

1.  **Create a new `Theme` resource:** In the Godot editor, right-click in the FileSystem dock, select `New Resource...`, search for `Theme`, and save it (e.g., `res://assets/themes/my_game_theme.tres`).
2.  **Edit the Theme:** Double-click the `.tres` file to open the Theme editor. Here, you can add and modify styles for various `Control` types (e.g., `Label`, `Button`, `Panel`).
    -   **Type:** Select the `Control` node type you want to style (e.g., `Label`).
    -   **Property:** Choose the property to modify (e.g., `font_color`, `font_size`, `normal` stylebox).
3.  **Apply the Theme:**
    -   **Project-wide:** Go to `Project → Project Settings → Gui → Theme` and set your custom theme as the `Custom Theme`. This will apply the theme to all UI elements in your project.
    -   **Scene-specific:** Apply the theme to a specific `Control` node's `theme` property. This theme will then apply to that node and all its children.

## Customizing AdvScreen

AdvScreen is built using standard Godot `Control` nodes, which means it fully respects Godot's theming system. You can customize its appearance by defining styles for the `Control` types it uses.

### Key AdvScreen Elements to Theme

-   **`Label`**: For dialogue text, character names, and menu options.
    -   Common properties: `font_color`, `font_size`, `font`, `outline_size`, `outline_color`.
-   **`Panel`**: For the background of the message box.
    -   Common properties: `panel` (a `StyleBox` resource for background drawing).
-   **`Button`**: For choice menu buttons.
    -   Common properties: `normal`, `hover`, `pressed`, `focus` styleboxes; `font_color`, `font_size`.

### Example: Changing Dialogue Font and Color

1.  Open your custom `Theme` resource.
2.  In the Theme editor, select `Add Type Override`.
3.  Choose `Label` as the type.
4.  Under `Label`, find `Colors → font_color` and set it to your desired color (e.g., `#FFFFFF` for white).
5.  Under `Label`, find `Fonts → font` and load your custom font resource (e.g., `res://assets/fonts/my_font.ttf`).

This will change the font and color of all `Label` nodes in your project that are affected by this theme, including the dialogue text in AdvScreen.

## Best Practices for Theming

-   **Start Simple:** Begin by modifying a few key properties (like font and main panel background) and expand from there.
-   **Organize Theme Files:** For complex themes, consider breaking them down into smaller `.tres` files for different sections (e.g., `dialogue_theme.tres`, `menu_theme.tres`) and then combining them in a master theme.
-   **Test Regularly:** Run your game frequently to see how your theme changes affect the UI.
-   **Use Theme Overrides:** For specific instances where you need a slight variation from the global theme, use the `Theme Overrides` section directly on the `Control` node in the Inspector.

---

By mastering Godot's theming system, you gain full control over the visual presentation of your Argode visual novel.
