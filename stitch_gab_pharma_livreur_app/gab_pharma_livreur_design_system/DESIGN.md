---
name: Gab'Pharma Livreur Design System
colors:
  surface: '#eefdf4'
  surface-dim: '#ceded5'
  surface-bright: '#eefdf4'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#e8f7ef'
  surface-container: '#e2f1e9'
  surface-container-high: '#dcece3'
  surface-container-highest: '#d7e6de'
  on-surface: '#111e19'
  on-surface-variant: '#3f4940'
  inverse-surface: '#26332e'
  inverse-on-surface: '#e5f4ec'
  outline: '#6f7a6f'
  outline-variant: '#bec9bd'
  surface-tint: '#076d38'
  primary: '#004f26'
  on-primary: '#ffffff'
  primary-container: '#006a35'
  on-primary-container: '#8fe7a5'
  inverse-primary: '#81d998'
  secondary: '#206b3d'
  on-secondary: '#ffffff'
  secondary-container: '#a8f4b9'
  on-secondary-container: '#287243'
  tertiary: '#004481'
  on-tertiary: '#ffffff'
  tertiary-container: '#005caa'
  on-tertiary-container: '#bdd5ff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#9df6b2'
  primary-fixed-dim: '#81d998'
  on-primary-fixed: '#00210c'
  on-primary-fixed-variant: '#005228'
  secondary-fixed: '#a8f4b9'
  secondary-fixed-dim: '#8cd79f'
  on-secondary-fixed: '#00210d'
  on-secondary-fixed-variant: '#005229'
  tertiary-fixed: '#d4e3ff'
  tertiary-fixed-dim: '#a5c8ff'
  on-tertiary-fixed: '#001c3a'
  on-tertiary-fixed-variant: '#004786'
  background: '#eefdf4'
  on-background: '#111e19'
  surface-variant: '#d7e6de'
typography:
  headline-lg:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
  headline-sm:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
  price-display:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 24px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  margin-mobile: 16px
  gutter-mobile: 12px
  touch-target-min: 48px
---

## Brand & Style
The design system focuses on **Operational Reliability** and **High Legibility**. Designed for delivery professionals in Gabon, the UI prioritizes clarity, speed of interaction, and accessibility in varying outdoor lighting conditions. 

The aesthetic is **Corporate / Modern** with a strong influence from **Material Design 3**. It utilizes large touch targets and a high-contrast color palette to ensure delivery drivers can manage "Courses Actives" (Active Orders) safely and efficiently. The tone is professional, medical-adjacent (given the pharmaceutical context), and deeply functional.

## Colors
The palette is rooted in a "Deep Green" primary color, symbolizing the pharmaceutical nature of the goods and professional trust. 

- **Primary (#006A35):** Used for main actions, headers, and active states.
- **Background (#EDFDF4):** A soft mint white that reduces screen glare compared to pure white, improving outdoor readability.
- **Surface (#FFFFFF):** Elevated cards and containers to create a clear "layer" between the UI and the background.
- **Accents:** 
    - **Blue (#005FAF):** Reserved for "In Progress" statuses and navigational cues.
    - **Amber (#8B6A00):** Used for deadlines and urgent timing indicators.
    - **Error (#BA1A1A):** Specifically for "Report Problem" (Signaler un problème) actions.

## Typography
This design system uses **Inter** exclusively to maximize legibility. 
- **Scale:** Sizes are slightly enlarged to cater to drivers who may be viewing the device at arm's length or while mounted on a dashboard.
- **Hierarchy:** High-weight headlines are used for addresses and client names. 
- **Price Display:** A specific role for FCFA amounts ensures financial information is never missed.

## Layout & Spacing
The layout follows a strict **8px grid system**. 

- **Fluid Mobile Grid:** A 4-column layout for mobile with 16px side margins.
- **Density:** Medium density. Elements are spaced generously to prevent accidental taps during transit.
- **Active Order Focus:** The current task (Course Active) should always occupy the primary focal point of the viewport, often using a sticky bottom sheet or a top-weighted card.
- **Safe Zones:** Ensure all primary buttons maintain a 48px minimum height and are placed within easy thumb-reach (bottom 1/3 of the screen).

## Elevation & Depth
Visual hierarchy is established using **Tonal Layers** and **Ambient Shadows** consistent with Material 3.

- **Level 0 (Background):** The #EDFDF4 surface.
- **Level 1 (Cards):** White surfaces (#FFFFFF) with a soft 4px blur, 10% opacity black shadow. These house order details and list items.
- **Level 2 (Active States):** Active orders use a 1px border of the Primary color (#006A35) in addition to shadow to differentiate them from pending tasks.
- **Floating Action Buttons (FAB):** High elevation (Level 3) with an 8px blur shadow to indicate primary navigational actions like "Start Route."

## Shapes
The shape language is friendly yet structured. 
- **Cards & Containers:** Use a 16px corner radius (rounded-lg) to create a modern, approachable feel.
- **Buttons:** Fully rounded (pill-shaped) for primary actions to distinguish them from informational cards.
- **Inputs:** 8px radius for a more technical, stable appearance.

## Components

### Buttons
- **Primary Action:** Full-width, pill-shaped, #006A35 background, White text. Min-height: 56px for "Confirm Delivery."
- **Secondary Action:** Outlined with Primary color, 2px stroke.
- **Urgent/Problem:** Background #BA1A1A for "Signaler un problème."

### Cards (Course Card)
- White background, 16px radius.
- Includes a dedicated header section for "Status" using Chips.
- Primary information (Address) in `headline-sm`.
- Secondary information (FCFA Amount, Items) in `body-md`.

### Status Chips
- **En cours:** Blue background (10% opacity), Blue text.
- **Terminé:** Green background (10% opacity), Green text.
- **Retard:** Amber background (10% opacity), Amber text.

### Inputs & Fields
- Inset labels for "Delivery Notes."
- Large, clear numeric pads for PIN verification.

### Icons
- Use **Material Symbols Rounded**. 
- Standard size: 24px. Large size for primary navigation: 32px.
- Key Icons: `delivery_dining` (Order), `route` (Itinerary), `inventory_2` (Inventory), `task_alt` (Complete), `report_problem` (Issue).