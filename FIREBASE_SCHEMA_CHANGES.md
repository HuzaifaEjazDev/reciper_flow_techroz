# Firebase Schema Changes for PlannedMeals

## Overview
The Firebase schema for PlannedMeals has been updated to save recipe data directly under date documents instead of creating sub-collections for meal types (breakfast, lunch, dinner, etc.).

## New Schema Structure

### Before (Old Schema)
```
users/{userId}/PlannedMeals/{dateForRecipe}/{mealType}/{mealId}
  - dateforrecipe: "2 Oct", "7 Oct", etc.
  - mealType: "breakfast", "lunch", "dinner", etc.
  - mealId: auto-generated ID
  - Data stored in sub-collections by meal type
```

### After (New Simplified Schema)
```
users/{userId}/PlannedMeals/{mealId}
  - mealId: auto-generated unique ID for recipe data
  - dateForRecipe and mealType stored as fields in the document
  - All recipe data stored directly in meal documents
```

## Data Fields in Each Meal Document

Each meal document now contains the following fields:

- **uniqueId**: Auto-generated unique ID for recipe data
- **recipeTitle**: Title of the recipe
- **dateForRecipe**: Date in format "D MMM" (e.g., "2 Oct", "7 Oct") - stored as field
- **timeForRecipe**: User-set time from dialog box
- **persons**: User-set number of persons from dialog box
- **ingredients**: List of ingredients (uploaded from admin app)
- **instructions**: List of cooking instructions (uploaded from admin app)
- **recipeImage**: Static image for all recipe data (currently using dish1.jpg)
- **mealType**: Type of meal (breakfast, lunch, dinner, etc.) - stored as field
- **createdAt**: Timestamp when the meal was created

## Files Modified

### 1. New Model: `lib/models/user/planned_meal.dart`
- Created new `PlannedMeal` class to represent the new data structure
- Includes methods for Firestore serialization/deserialization
- Supports all required fields as specified

### 2. Updated Service: `lib/services/firestore_recipes_service.dart`
- Added new methods for the simplified schema:
  - `savePlannedMeal()`: Save meal data directly in PlannedMeals collection
  - `getPlannedMealsForDate()`: Query meals by dateForRecipe field
  - `getPlannedMealsForWeek()`: Query meals for multiple dates using whereIn
  - `deletePlannedMeal()`: Delete a specific meal by ID
  - `updatePlannedMeal()`: Update meal data by ID
  - `formatdateForRecipe()`: Helper to format dates as "D MMM"

### 3. Updated ViewModel: `lib/viewmodels/user/meal_planner_view_model.dart`
- Completely rewritten to work with new schema
- Uses `PlannedMeal` model instead of old structure
- Maintains compatibility with existing UI components
- Converts between `PlannedMeal` and `MealEntry` for UI compatibility

## Key Benefits

1. **Ultra-Simplified Structure**: No nested sub-collections at all
2. **Direct Data Storage**: All recipe data stored directly in meal documents
3. **Better Performance**: Single collection queries with field-based filtering
4. **Easier Management**: One collection for all planned meals
5. **Consistent Data**: All required fields stored in one place
6. **Flexible Querying**: Can easily query by date, meal type, or any combination

## Migration Notes

- The old schema structure is no longer used
- All new meal planning will use the new schema
- Existing data in the old format will need to be migrated separately
- The UI remains unchanged as the ViewModel handles the conversion

## Testing

A test file `lib/test_new_schema.dart` has been created to demonstrate the new schema functionality. This file can be deleted after testing is complete.

## Usage Example

```dart
// Create a planned meal
final PlannedMeal plannedMeal = PlannedMeal(
  uniqueId: '', // Auto-generated
  recipeTitle: 'Chicken Pasta',
  dateForRecipe: '2 Oct',
  timeForRecipe: '12:30',
  persons: 4,
  ingredients: ['500g chicken breast', '300g pasta'],
  instructions: ['Cut chicken', 'Boil pasta'],
  recipeImage: 'assets/images/dish/dish1.jpg',
  mealType: 'lunch',
  createdAt: DateTime.now(),
);

// Save to Firestore
final String mealId = await service.savePlannedMeal(plannedMeal);

// Retrieve meals for a date
final List<PlannedMeal> meals = await service.getPlannedMealsForDate('2 Oct');
```
