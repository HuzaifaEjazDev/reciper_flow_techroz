# Debugging Steps for Ingredients and Instructions Issue

## Problem
Ingredients and instructions fields are empty when saving planned meals from admin recipes.

## Debugging Steps

### Step 1: Test Firestore Data Structure
1. **Run the app** and go to the meal planner screen
2. **Tap the "Test Recipe Data" button** (temporary button added)
3. **Check the console output** to see:
   - What fields exist in the recipe documents
   - What the raw ingredients and steps data looks like
   - Whether the data is in the expected format

### Step 2: Test Data Extraction
1. **Navigate to admin recipes** (Add Meal → Admin Recipes)
2. **Check the console output** for debug messages showing:
   - Raw recipe data from Firestore
   - Extracted ingredients and steps
   - AdminRecipeCardData creation

### Step 3: Test MealEntry Creation
1. **Select a recipe** from admin recipes
2. **Check the console output** for debug messages showing:
   - RecipeDetailsScreen receiving ingredients/steps
   - MealEntry creation with ingredients/instructions
   - MealEntry being passed back to meal planner

### Step 4: Test PlannedMeal Creation
1. **Add the recipe to meal planner**
2. **Check the console output** for debug messages showing:
   - MealEntry ingredients/instructions received
   - PlannedMeal creation with ingredients/instructions
   - Data being saved to Firestore

### Step 5: Test Firestore Retrieval
1. **Use the test function** to retrieve planned meals
2. **Check the console output** to see if ingredients/instructions are saved correctly

## Expected Debug Output

### When testing Firestore data:
```
=== Testing Firestore Recipe Data ===
Fetched X recipes from Firestore
=== First Recipe Data ===
ID: [recipe_id]
Title: [recipe_title]
All keys: [list_of_keys]
=== Ingredients Check ===
ingredients field: [ingredients_data]
=== Steps/Instructions Check ===
steps field: [steps_data]
```

### When adding a recipe from admin:
```
=== RAW RECIPE DATA ===
ID: [recipe_id], Title: [recipe_title]
Raw ingredients field: [ingredients_data]
Raw steps field: [steps_data]
All keys in recipe data: [list_of_keys]
_extractStringList called with keys: [ingredients, ingredientsList]
Checking key "ingredients": [data] (type: [type])
...
AdminRecipeCard tapped - Title: [recipe_title]
AdminRecipeCard ingredients: [extracted_ingredients]
AdminRecipeCard steps: [extracted_steps]
Creating MealEntry with ingredients: [ingredients]
Creating MealEntry with steps: [steps]
MealEntry ingredients: [ingredients]
MealEntry instructions: [instructions]
Adding meal to day: [recipe_title]
Meal ingredients: [ingredients]
Meal instructions: [instructions]
Created PlannedMeal with ingredients: [ingredients]
Created PlannedMeal with instructions: [instructions]
```

## Possible Issues to Look For

1. **Firestore Data Structure**: Ingredients/steps might be stored in different field names
2. **Data Format**: Ingredients/steps might be stored as objects instead of strings
3. **Extraction Logic**: The `_extractStringList` method might not handle the data format correctly
4. **Data Passing**: Ingredients/steps might be lost during screen navigation

## Files to Check

1. **lib/test_recipe_data.dart** - Test Firestore data structure
2. **lib/viewmodels/user/admin_recipes_view_model.dart** - Data extraction logic
3. **lib/views/screens/recipe_by_admin_screen.dart** - Data passing to RecipeDetailsScreen
4. **lib/views/screens/recipe_details_screen.dart** - MealEntry creation
5. **lib/viewmodels/user/meal_planner_view_model.dart** - PlannedMeal creation

## Next Steps

1. Run the tests and check console output
2. Identify where the data is being lost
3. Fix the specific issue found
4. Remove debug logging once fixed
5. Remove temporary test button
