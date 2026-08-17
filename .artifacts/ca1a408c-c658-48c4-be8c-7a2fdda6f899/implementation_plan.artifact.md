# Order Success Screen Implementation

This plan introduces a dedicated "Order Success" screen that appears immediately after a successful checkout. It provides visual confirmation using animations and automatically redirects the user to the order tracking page.

## Proposed Changes

### [New Screen]

#### [NEW] [order_success_screen.dart](file:///home/tamizharasan/AndroidStudioProjects/maruthi_eats/lib/screens/order_success_screen.dart)
- Create a stateless or stateful widget that:
    - Takes `orderId` as a required parameter.
    - Displays a "Congratulations!" or "Order Placed Successfully" message.
    - Shows a Lottie animation (`assets/animations/order_confirmed.json`) for visual confirmation.
    - Uses a 3-second delay (via `Future.delayed` in `initState`) to automatically navigate to `OrderTrackingScreen`.
    - Includes a "Track My Order" button for users who don't want to wait.

### [Checkout Integration]

#### [MODIFY] [checkout_screen.dart](file:///home/tamizharasan/AndroidStudioProjects/maruthi_eats/lib/screens/checkout_screen.dart)
- Update the `_placeOrder` method to navigate to `OrderSuccessScreen` instead of `OrderTrackingScreen` upon successful Firestore order creation.

## Verification Plan

### Manual Verification
1.  **Placement Flow**: Place a test order (using COD). Verify that the app transitions to a beautiful Success screen.
2.  **Auto-Redirection**: Wait on the Success screen without interaction. Verify that after 3 seconds, it automatically navigates to the Tracking screen.
3.  **Manual Override**: Tap the "Track My Order" button immediately. Verify it skips the wait and goes to the Tracking screen correctly.
4.  **UI Review**: Ensure the Lottie animation plays correctly and the brand colors (Maroon/Gold) are respected.
