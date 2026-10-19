# TRAVIO — Design System & Product Specification

> Currency & Travel

Version: 1.0
Platform: iPhone
Status: Design Specification
Product Type: Premium Travel & Currency App

---

# 1. PRODUCT VISION

TRAVIO is a premium currency and travel companion designed to make
currency conversion, exchange-rate tracking and travel spending
simple, fast and intuitive.

TRAVIO should feel:

- Premium
- Editorial
- Minimal
- Intuitive
- Fast
- International
- Calm
- Personal

TRAVIO should NOT feel like:

- A traditional banking app
- An accounting application
- A trading platform
- A generic currency converter
- A tourism application overloaded with information

The core product philosophy is:

> Know what your money is worth without having to think about it.

---

# 2. CORE PRODUCT

TRAVIO combines:

1. Currency conversion
2. Exchange-rate tracking
3. Exchange-rate alerts
4. Travel management
5. Travel expense tracking
6. Budget tracking
7. Favorites
8. Offline functionality
9. Widgets
10. Premium subscription

---

# 3. PRODUCT STRUCTURE

The primary navigation contains four sections:

```text
Convert
Trips
Alerts
You

There is NO dedicated Rates tab.

Rates are integrated into the Convert experience.

4. NAVIGATION
4.1 Convert

Primary currency conversion experience.

Responsibilities:

Currency conversion
Currency selection
Favorite currency pairs
Exchange-rate information
Historical rates
Rate details
Rate freshness
Offline conversion

The Convert screen is the primary entry point of the application.

The converter must visually dominate the screen.

4.2 Trips

Travel management.

Responsibilities:

Create trips
View active trips
View upcoming trips
View past trips
Manage trip currencies
Manage budgets
Manage expenses
Calculate expenses
View spending summaries

Users can create and maintain multiple trips.

Example:

Japan
Active

London
Upcoming

New York
Past

Trips must not become dashboard-heavy.

The experience should prioritize:

Destination
Currency
Budget
Spending
Remaining budget
Recent expenses

Graphs are NOT used inside Trips.

4.3 Alerts

Currency-pair alerts.

Users can configure multiple alerts for the same currency pair.

Supported alert types:

Percentage movement

Notify when a pair moves above or below a specified percentage.

Example:

EUR / USD

Notify me if:
+5%
-5%
Target exchange rate

Notify when a currency pair reaches a specified value.

Example:

EUR / USD

Notify me when:
1 EUR = 1.20 USD

Both alert types can exist simultaneously for the same pair.

Alerts are a Premium-only feature.

4.4 You

Account and application settings.

Responsibilities:

Subscription
Account
Preferences
Appearance
Default currency
Notifications
Offline data
Privacy
Terms
Support
Restore purchases
5. CONVERSION EXPERIENCE

The conversion experience is the heart of TRAVIO.

The user should be able to:

Enter an amount
Select a currency
Immediately see the converted value

The interaction should require as few actions as possible.

Example:

             €100.00

                 ↓

             ¥17,482

        EUR              JPY

     1 EUR = ¥174.82

     Updated 2 min ago

The amount is the visual hero.

6. CURRENCY SELECTION

Currency selection must use a custom TRAVIO interface.

Do NOT use a generic platform dropdown.

The currency selector should contain:

Search
Popular currencies
Recent currencies
Favorite pairs
All supported currencies

Currencies use custom iconography.

Do NOT rely on system emoji flags.

Example:

Search currencies...

Popular

[Custom Icon] USD
US Dollar

[Custom Icon] EUR
Euro

[Custom Icon] JPY
Japanese Yen

[Custom Icon] GBP
British Pound
7. CURRENCY DATA

When a user selects a currency, TRAVIO should load the relevant exchange-rate data for that currency.

The application should not require the user to manually configure exchange-rate pairs before conversion.

Example:

User selects JPY

        ↓

TRAVIO loads JPY rates

        ↓

EUR → JPY
USD → JPY
GBP → JPY
...

The architecture should support caching the latest downloaded rates.

8. OFFLINE MODE

TRAVIO must support offline usage.

Offline functionality includes:

Using the latest downloaded exchange rate
Viewing saved trips
Viewing saved expenses
Adding expenses
Performing conversions using cached rates
Using favorite pairs
Accessing previously downloaded currency data

The application must clearly communicate when a rate is based on cached data.

Example:

¥174.82

Last updated
Sep 28 · 12:42

Offline

The user should never mistake a cached rate for a live rate.

9. RATE CACHING

TRAVIO stores the latest successfully downloaded rate data locally.

Each cached rate should contain at minimum:

Base currency
Quote currency
Rate
Timestamp
Data source/version if available

When offline:

Latest cached rate
        ↓
Conversion

When online:

Fresh data available
        ↓
Update cache
        ↓
Update UI
10. FAVORITES

Favorites are based on currency pairs.

Example:

EUR → USD
EUR → JPY
EUR → GBP
EUR → CHF

A favorite pair should provide quick access to conversion.

Favorites should be accessible from the Convert screen.

11. TRAVEL MODE

Travel Mode is one of the main differentiating features of TRAVIO.

It transforms TRAVIO from a currency converter into a travel money companion.

12. CREATE TRIP

A user can create a trip by defining:

Destination
Local currency
User/home currency
Start date
End date
Optional budget

Example:

Japan

Home currency:
EUR

Local currency:
JPY

Sep 28 — Oct 8

Budget:
€1,500

The selected currencies are remembered for the trip.

13. TRIP CONVERSION

Once a trip has been configured, the user should NOT have to repeatedly select currencies.

Example:

Japan 🇯🇵

EUR → JPY

During the trip:

1200

immediately becomes:

¥1,200
≈ €6.86

The conversion should be instant.

The primary interaction should prioritize speed.

14. TRIP CALCULATOR

The calculator is integrated directly into the Trips experience.

It is NOT a separate bottom-navigation destination.

Example:

Japan

RAMEN       ¥1,200
DRINK         ¥450
TRAIN         ¥820
TAXI        ¥2,300
------------------
TOTAL       ¥4,770

            ↓

          €27.40

The user can convert and save the result as an expense.

15. EXPENSES

Expenses can be saved directly from the trip calculator.

Each expense should contain:

Name
Original amount
Original currency
Converted amount
Home currency
Exchange rate at purchase
Timestamp
Category
Trip ID

Example:

Ramen

¥1,200

Exchange rate:
1 EUR = ¥174.82

Value:
€6.86

Category:
Food
16. HISTORICAL EXCHANGE RATE FOR EXPENSES

This is a critical product rule.

When an expense is created, TRAVIO stores the exact exchange rate used at that moment.

The expense MUST NOT dynamically change its historical converted value when current exchange rates change.

Example:

Purchase:

¥1,200
Rate:
1 EUR = ¥174.82

Stored value:
€6.86

If the exchange rate later becomes:

1 EUR = ¥180.00

the historical expense remains:

€6.86

This ensures travel spending statistics remain historically consistent.

17. EXPENSE CATEGORIES

Default categories:

Food
Transport
Hotel
Shopping
Entertainment
Other

Categories should use custom TRAVIO iconography.

Emoji must NOT be used as the primary visual system.

The system should be designed so additional categories can be introduced later.

18. TRIP BUDGET

Users can optionally define a trip budget.

Example:

Japan

Budget
€1,500

Spent
€438

Remaining
€1,062

The interface should visually communicate budget consumption without requiring a graph.

Example:

€438 / €1,500

██████░░░░░░░░░

29%

The actual implementation should use a refined visual progress component rather than literal text characters.

19. TRIP EXPENSE SUMMARY

Trips should provide clear spending information.

Example:

Japan

Food
€124

Transport
€87

Shopping
€156

Hotel
€0

Other
€71

The emphasis should be on readability.

Graphs are intentionally excluded from Trips.

20. TRIP HISTORY

Users can maintain multiple trips.

Trip states:

Upcoming
Active
Past

Past trips remain accessible.

Historical trip data must not be deleted automatically.

Example:

TRIPS

Japan
Active

London
Upcoming

New York
Past
21. EXCHANGE RATES

Exchange-rate information lives inside Convert.

The user can access detailed rate information without leaving the primary conversion context.

Example:

EUR / JPY

¥174.82

Updated 2 min ago

1D   1W   1M   3M   1Y

Historical exchange-rate charts belong here, NOT inside Trips.

22. ALERTS

Users can create alerts for favorite or non-favorite currency pairs.

Supported conditions:

Percentage increase
Percentage decrease
Target rate

Example:

EUR / USD

Target:
1.2000

or:

EUR / USD

Movement:
+5%

Multiple alerts can exist for the same pair.

Alerts are Premium-only.

23. SUPPORTED CURRENCIES

TRAVIO is designed to support more than 208 currencies/currency assets where supported by the selected data provider.

Russian currency support is explicitly required.

The currency architecture must not hard-code a small fixed list.

The application must be able to accommodate new currencies from the data provider.

24. PREMIUM MODEL

TRAVIO has NO permanent free tier.

The user may:

Download the app
Open the app
Complete onboarding
View the subscription paywall

The user cannot use the application's core functionality without an active subscription.

25. SUBSCRIPTIONS

TRAVIO uses auto-renewable subscriptions.

Weekly
$0.99 / week

No free trial

Designed primarily for short-term travelers.

Monthly
$2.99 / month

7-day free trial
Annual
$29.99 / year

7-day free trial

BEST VALUE

The annual plan should be visually emphasized.

26. PAYWALL

The paywall should feel premium and editorial.

Example hierarchy:

TRAVIO PRO

Currency made simple.
Built for every trip.

[Premium benefits]

ANNUAL
$29.99 / year
BEST VALUE
7-day free trial

MONTHLY
$2.99 / month
7-day free trial

WEEKLY
$0.99 / week

Continue

The interface must clearly communicate:

Price
Billing period
Free-trial duration
Automatic renewal
Cancellation information

Copy must never imply that a paid subscription is free.

The Weekly plan does not include a free trial.

27. VISUAL IDENTITY
27.1 Design Direction

TRAVIO follows a:

Premium / Editorial

design direction.

Characteristics:

Strong typography
Large numerical hierarchy
Generous whitespace
Carefully composed layouts
Minimal UI chrome
Refined transitions
Strong visual rhythm
Custom iconography

TRAVIO should feel designed rather than assembled from standard iOS components.

28. COLOR SYSTEM
Brand Accent
TRAVIO Teal

#3B9C9C

This is the primary brand identity color.

It should not dominate every screen.

It is primarily used for:

Primary actions
Active states
Highlights
Selected elements
Brand moments
Important interactive feedback
29. LIGHT MODE
Background
#F7F7F5

Primary Text
#151515

Secondary Text
#7C7C78

Cards / Surfaces
#FFFFFF

Borders
#E7E7E3

Light Mode should feel warm rather than sterile.

Pure white should be used selectively.

30. DARK MODE
Background
#0F1010

Surface
#171918

Primary Text
#F4F4F0

Secondary Text
#929692

Accent
#58B9B3

Dark Mode should feel sophisticated and calm.

Avoid pure black backgrounds.

31. TRAVEL / CURRENCY ACCENTS

Countries and trips can have secondary accent colors.

These colors are contextual rather than global brand colors.

Example:

Japan
#E86A6A

United States
#5B7CFA

United Kingdom
#5969C9

France
#6B8FD4

Italy
#6FAF8A

These colors should be used subtly for:

Trip indicators
Small accents
Selected states
Icons
Progress indicators
Contextual visual details

They should NOT recolor entire screens.

TRAVIO must maintain a consistent visual identity regardless of destination.

32. TYPOGRAPHY
Primary UI Typeface
SF Pro

Used for:

Navigation
Labels
Buttons
Descriptions
Headings
Settings
General interface

SF Pro provides the native Apple foundation.

Numerical Typeface
IBM Plex Mono

Used selectively for:

Currency amounts
Exchange rates
Financial values
Numerical data
Important numerical displays

Example:

€100.00

¥17,482

1 EUR = ¥174.82

IBM Plex Mono should visually distinguish financial information without overwhelming the interface.

Do NOT use IBM Plex Mono for normal body copy.

33. TYPOGRAPHIC HIERARCHY

Numbers are one of the main visual elements of TRAVIO.

Example:

EUR

€100.00

should give significantly more visual weight to:

€100.00

than:

EUR

Typography should communicate hierarchy before color or decoration.

34. ICONOGRAPHY

TRAVIO uses custom iconography.

Do NOT rely on emoji as the primary interface language.

Icons should be:

Minimal
Geometric
Consistent
Refined
Recognizable
Designed specifically for TRAVIO

Currency icons and country indicators should belong to the same visual family.

35. APP ICON / LOGO DIRECTION

The logo should combine the concepts of:

Travel
+
Movement
+
Currency exchange

Conceptual direction:

An abstract symbol representing movement between two points combined with an exchange / conversion relationship.

Possible visual language:

Point A
   ↘
     ↔
   ↗
Point B

or:

Route
  +
Exchange

The final symbol should be abstract enough to work independently from the wordmark.

The logo should work in:

App Icon
Splash / launch context
Website
Widget
App Store assets
Wordmark

The logo should NOT rely on:

Literal airplane illustrations
Dollar symbols
Generic globe icons
Currency symbols as the main shape
Overly detailed travel imagery

The objective is a recognizable, ownable symbol.

36. APP ICON

The App Icon should prioritize the symbol over the word "TRAVIO".

The icon must remain recognizable at small sizes.

It should work in both:

Light environments
Dark environments

The icon should use the TRAVIO brand identity but may use a controlled secondary color relationship.

The final icon should feel like a premium utility rather than a generic travel application.

37. HOME / CONVERT SCREEN

The Convert screen is the first and most important screen.

The visual hierarchy should be approximately:

TRAVIO

        Amount

          ↓

     Converted Amount

Exchange rate
Last updated

Recent / Favorite pairs

The interface should not become a dashboard.

The conversion itself is the hero.

38. CONVERSION INTERACTIONS
Swap

A custom interaction swaps:

EUR → JPY

to:

JPY → EUR

The transition should be animated subtly.

Amount input

The amount should be directly editable.

Currency selector

Opens a custom search and selection interface.

Rate details

Allows the user to inspect additional exchange-rate information.

39. MICROINTERACTIONS

Animations should be:

Fast
Smooth
Purposeful
Subtle

Examples:

Currency swap

Currencies exchange positions.

Conversion

The result updates smoothly.

Add expense

The expense visually joins the trip history.

Save favorite

The favorite icon responds with a small confirmation animation.

Alert created

The alert transitions into the active alert list.

Avoid decorative animations without functional purpose.

40. WIDGET DIRECTION

Widgets are part of the future TRAVIO roadmap.

Initial concept:

┌────────────────────────────┐
│ EUR → JPY                  │
│                            │
│ €1              ¥174.82    │
│                            │
│ Updated 12:42              │
└────────────────────────────┘

The widget should prioritize:

Current rate
Currency pair
Last update
Immediate readability

Widgets should inherit the TRAVIO visual identity.

Widget implementation can be introduced after the core application.

41. RESPONSIVE DESIGN

Initial platform:

iPhone

The design system should still use reusable components and flexible layouts so that iPad support can be introduced later without redesigning the entire product.

42. COMPONENT PHILOSOPHY

Components should prioritize:

Simplicity
Consistency
Reusability
Accessibility
Visual hierarchy

Core components will include:

CurrencyAmount
CurrencySelector
CurrencyPair
RateDisplay
RateChart
FavoritePair
TripCard
ExpenseRow
BudgetProgress
CategoryRow
AlertCard
PrimaryButton
SecondaryButton
PaywallPlan
BottomSheet
Toast / Feedback
EmptyState
LoadingState
OfflineIndicator
43. STATES

Every major screen and component must define:

Default
Loading
Loaded
Empty
Error
Offline
Updating
Disabled
Premium locked

The user should always understand what is happening.

44. LOADING

Loading states should avoid generic full-screen spinners wherever possible.

Prefer:

Skeletons
Subtle placeholders
Animated numerical transitions

The application should feel fast even when network requests are occurring.

45. OFFLINE STATE

Offline mode should be visible but unobtrusive.

Example:

Offline

Using rates from
12:42

The application should remain usable whenever cached information is available.

46. ERROR STATES

Errors should be concise and actionable.

Example:

Couldn't update rates.

Your last available rates
are still available.

Try again

Do not expose technical errors to the user.

47. EMPTY STATES

Empty states should explain what the user can do next.

Example:

No trips yet.

Create your first trip
and keep your travel spending
in one place.

Create Trip
48. ACCESSIBILITY

TRAVIO must support:

Dynamic Type where appropriate
Sufficient contrast
VoiceOver
Large accessibility text
Touch targets appropriate for iOS
Meaningful accessibility labels
Color not being the only indicator of state

Secondary country colors must never be the sole way to communicate information.

49. UX PRINCIPLES
Principle 1

One screen, one primary purpose.

Principle 2

Numbers are the hero.

Principle 3

Remove unnecessary decisions.

Principle 4

Travel mode should eliminate repetitive currency selection.

Principle 5

Historical expenses must remain historically accurate.

Principle 6

Offline should be useful, not an error state.

Principle 7

Premium should feel valuable, not restrictive.

Principle 8

Visual personality should come from typography, spacing, composition and custom iconography.

Principle 9

Color should support hierarchy rather than replace it.

Principle 10

Every interaction should feel intentional.

50. PRODUCT DIFFERENTIATION

TRAVIO differentiates itself through the combination of:

Currency Converter
        +
Exchange Rates
        +
Alerts
        +
Travel Mode
        +
Expense Tracking
        +
Budget Tracking
        +
Offline Support
        +
Premium Editorial UI

The product should not compete solely as another currency converter.

Its positioning is:

A premium travel money companion.

51. CORE USER FLOW
First launch
Launch
  ↓
Onboarding
  ↓
TRAVIO value proposition
  ↓
Premium paywall
  ↓
Subscription
  ↓
Convert

There is no permanent free mode.

52. FIRST CONVERSION

After subscribing:

Convert
  ↓
Select base currency
  ↓
Select target currency
  ↓
Enter amount
  ↓
Instant conversion

The app should minimize setup.

53. TRIP FLOW
Trips
  ↓
Create Trip
  ↓
Destination
  ↓
Home Currency
  ↓
Local Currency
  ↓
Dates
  ↓
Optional Budget
  ↓
Trip Created

During trip:

Trip
  ↓
Quick Conversion
  ↓
Calculator
  ↓
Save Expense
  ↓
Category
  ↓
Trip Spending Updated
54. ALERT FLOW
Alerts
  ↓
Create Alert
  ↓
Select Currency Pair
  ↓
Choose Condition
  ↓
Percentage OR Target
  ↓
Set Value
  ↓
Enable Notification

Both percentage and target alerts can coexist for the same pair.

55. SUBSCRIPTION PHILOSOPHY

TRAVIO is a subscription-first product.

The subscription should be justified by continuous value:

Updated exchange-rate information
Alerts
Offline currency data
Travel functionality
Historical information
Widgets
Continuous product improvements

The subscription experience must be transparent.

No deceptive interaction patterns.

56. DESIGN LANGUAGE SUMMARY

TRAVIO should feel like:

Premium
        +
Editorial
        +
Travel
        +
Financial precision
        +
Apple quality

The visual language should be recognizable without depending on excessive decoration.

57. FINAL DESIGN PRINCIPLE

TRAVIO should make a complicated concept feel simple.

The user should never need to think:

"How do I use this app?"

They should simply think:

"How much is this worth?"

And TRAVIO should answer immediately.