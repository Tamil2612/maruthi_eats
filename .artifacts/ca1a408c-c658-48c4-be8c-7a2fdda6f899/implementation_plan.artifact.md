# Professional Order Tracking UI & Bill Details Integration

This plan focuses on making the `OrderTrackingScreen` as informative and professional as the `Cart` and `Checkout` screens. It ensures all saved details (coupons, address labels, price breakdowns) are clearly visible to the user.

## Proposed Changes

### [Models]

#### [MODIFY] [order.dart](file:///home/tamizharasan/AndroidStudioProjects/maruthi_eats/lib/models/order.dart)
- Update `OrderModel` to include the `addressLabel` field.
- Update `fromFirestore` to map the `address_label` from the database.

### [Screens]

#### [MODIFY] [order_tracking_screen.dart](file:///home/tamizharasan/AndroidStudioProjects/maruthi_eats/lib/screens/order_tracking_screen.dart)
- **Enhanced Header**: Add a more detailed header showing order timestamp and a cleaner ID presentation.
- **Bill Details Integration**:
    - Re-implement the "Bill Details" section to mirror the `CartScreen` style.
    - Explicitly show the **Coupon Code** used (e.g., "SAVEMORE applied").
    - Include Taxes if they are stored in the order.
- **Delivery Address Card**:
    - Add a specialized card for delivery details.
    - Show the `addressLabel` (e.g., "Home", "Work") prominently with its icon.
- **"Need Help?" Section**:
    - Add a footer section with quick actions for contacting support or viewing policies.
- **UI Polish**: Use professional card grouping, consistent margins, and better typography.

## Verification Plan

### Manual Verification
1.  **Placement to Tracking**: Place an order with a coupon. Verify the tracking screen shows the correct coupon code and discount amount.
2.  **Address Context**: Verify that the address section shows the correct label (e.g., "Home") instead of just the raw address string.
3.  **Bill Consistency**: Compare the "Bill Details" in the Tracking screen with the "Bill Details" in the Cart. They should look identical in terms of structure and styling.
4.  **Empty State / Loading**: Ensure the shimmer or loading indicator looks smooth on slower connections.
