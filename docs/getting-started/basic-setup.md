# Basic Setup Guide

This guide covers the essential setup steps for your Godot project to work with Argode.

## Setup Autoload

1. Open **Project Settings** (`Project → Project Settings`)
2. Go to **Autoload** tab
3. Add **ArgodeSystem**:
   - **Path**: `res://addons/argode/core/ArgodeSystem.gd`
   - **Node Name**: `ArgodeSystem`
   - Check **Enable**

![Autoload Setup](../images/autoload-setup.png)

## Set as Main Scene

1. Create a new scene (`Scene → New Scene`) if you haven't already, and save it (e.g., `Main.tscn`).
2. Go to **Project Settings** (`Project → Project Settings`).
3. Under the **Application → Run** section, set **Main Scene** to your `Main.tscn` (or whatever you named your main scene).
4. Press **F5** to run your project.
