# מחקר 02 — Apple, פרטיות, גילאים ו-App Store

תאריך: 4 בנובמבר 2026  
סטטוס: מיפוי ראשוני לפי מסמכי Apple הרשמיים. אינו ייעוץ משפטי ואינו מבטיח אישור.

## מסקנות

1. כל אפליקציית iOS חייבת Privacy Policy URL ב-App Store Connect וקישור נגיש מתוך האפליקציה.
2. יש לדווח ב-App Store Connect על נוהלי איסוף הנתונים של האפליקציה ושל כל SDK/שותף צד שלישי.
3. Apple מחייבת חוויית תוכן מותאמת גיל; דירוג הגיל נקבע באמצעות שאלון App Store Connect.
4. Kids Category כוללת דרישות מחמירות יותר, לרבות Parental Gates והגבלות על קישורים, רכישות ופרסום.
5. מאחר שהמוצר מיועד לקהל רחב, יש להחליט אם הוא באמת מיועד בעיקר לילדים. המלצה ראשונית: לא לבחור Kids Category ולא לסמן Made for Kids אלא אם המוצר והמודל העסקי נבנו כדי לעמוד בדרישות הקטגוריה.
6. אין להוסיף פרסומות או Analytics בגרסה הראשונה.
7. רכישות דיגיטליות עתידיות בתוך האפליקציה צריכות להשתמש ב-In-App Purchase של Apple, בהתאם לכללים.

## Multi-Touch — תכנון טכני

Apple UIKit תומכת במספר נגיעות בו-זמנית:
- יש להפעיל isMultipleTouchEnabled על ה-UIView הרלוונטי.
- יש לעבד touchesBegan, touchesMoved, touchesEnded ו-touchesCancelled.
- יש לשמור מזהה יציב לכל UITouch לאורך חיי המגע, ולא להסתמך על סדר Set או על מיקום האצבע בלבד.
- יש לבדוק בפועל כמה נגיעות נתמכות במכשירי iPhone שונים; אין להבטיח מספר אחיד ללא בדיקה.
- במקרה של ביטול מגע, יציאה מהמסך, שיחת מערכת או מעבר מצב — יש לנקות את מצב המגעים ולמנוע בחירה שגויה.

מקורות:
- https://developer.apple.com/documentation/uikit/uiresponder/touchesbegan(_:with:)
- https://developer.apple.com/documentation/uikit/handling-touches-in-your-view

## App Store Review

דרישות רלוונטיות:
- האפליקציה חייבת להיות שלמה ויציבה, ללא Placeholder או קישורים לא פעילים.
- צילומי המסך צריכים להראות את האפליקציה בפעולה.
- שם האפליקציה מוגבל ל-30 תווים.
- דירוג הגיל חייב לשקף את התוכן והיכולות בפועל.
- תוכן מסוכן, משפיל, פוגעני או המעודד התנהגות מסוכנת עלול לגרום לדחייה.
- רכישות דיגיטליות כפופות לכללי In-App Purchase.

מקורות:
- https://developer.apple.com/app-store/review/guidelines/
- https://developer.apple.com/help/app-store-connect/reference/app-information/app-information
- https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating
- https://developer.apple.com/app-store/categories/

## פרטיות

נדרש:
- Privacy Policy ציבורית, מדויקת ונגישה.
- קישור למדיניות בתוך האפליקציה וב-App Store Connect.
- הצהרת App Privacy ב-App Store Connect, כולל SDKs של צד שלישי.
- הצהרה של "לא אוספים נתונים" אפשרית רק לאחר אימות הקוד וה-SDKs בפועל.
- אם יתווספו Analytics, Ads, Cloud Sync, Accounts או Purchases — לעדכן את המדיניות וההצהרות בהתאם.

החלטת תכנון מומלצת ל-MVP:
- ללא חשבון או שרת.
- ללא מיקום, אנשי קשר, תמונות, מיקרופון או מצלמה.
- ללא פרסומות וללא SDK לניתוח שימוש.
- שמירת הגדרות/סטטיסטיקה מקומית בלבד.

מקורות:
- https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy
- https://developer.apple.com/app-store/app-privacy-details/
- https://developer.apple.com/app-store/review/guidelines/

## גילאים ותוכן

יש מתח בין הרצון להתאים לילדים, בני נוער ומבוגרים לבין תוכן משימות למבוגרים:
- אם מאגר המשימות כולל תוכן למבוגרים, דירוג הגיל עשוי לעלות גם אם המשתמש בוחר מצב ילדים.
- בחירת גיל ידנית אינה תחליף לאימות גיל או להגנות שנדרשות במקרים הרלוונטיים.
- Kids Category דורשת Parental Gates ותנאים נוספים.
- אין לכלול בגרסה הראשונה תוכן מיני, מסוכן, משפיל, שימוש באלכוהול/סמים או אתגרים פיזיים מסוכנים.

המלצה:
- MVP: Finger Picker בלבד, ואולי Team Split.
- אם יתווספו משימות, להתחיל בתוכן Family-Safe בלבד.
- לבחון חבילות 13+/16+/18+ רק לאחר בדיקת ההשלכות על דירוג הגיל, מדיניות Apple והדין החל.
- תמיד לאפשר Skip/Pass ללא עונש; לנסח משימות כהזמנה ולא כהוראה כפויה.

## שם ומותג

אין להניח ששם פנוי ב-App Store רק משום שלא נמצאה תוצאה בחיפוש. יש לבדוק:
1. App Store לפי מדינות ושפות.
2. Google Play ואתרים/משחקים קיימים.
3. EUIPO eSearch ו-TMview.
4. BOIP עבור Benelux.
5. WIPO Global Brand Database.
6. דומיין ורשתות חברתיות.
7. זמינות בפועל ב-App Store Connect לפני הכרעה.

השם Finger Party אינו מומלץ כרגע: קיים מוצר בשם Finger's Party ב-App Store וגם משחק Finger Party ב-Steam.

מקורות:
- https://www.euipo.europa.eu/en/search-ip
- https://www.wipo.int/en/web/global-brand-database
- https://economie.fgov.be/en/themes/intellectual-property/research-tools/searching-trademarks-databases
- https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/

## Pro בעתיד

אין לבנות מערכת תשלום פעילה כרגע. יש להפריד ארכיטקטונית בין יכולות Free, יכולות Premium עתידיות ושכבת Entitlements.
- לרכישות עתידיות להשתמש ב-StoreKit 2.
- לבחון תחילה רכישה חד-פעמית של חבילות תוכן או Unlock קבוע.
- לא להוסיף מנוי אלא אם יש ערך מתמשך ברור שמצדיק חיוב חוזר.

מקורות:
- https://developer.apple.com/storekit/
- https://developer.apple.com/documentation/storekit/getting-started-with-in-app-purchases-using-storekit-views
- https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/overview-for-configuring-in-app-purchases

## החלטות פתוחות

- שם המותג הסופי.
- האם גרסת ההשקה כוללת רק Finger Picker או גם Team Split.
- האם Truth or Dare נכנס לגרסה הראשונה (המלצה: לא).
- דירוג גיל יעד לפי התוכן הסופי.
- האם להפיץ מחוץ ל-Kids Category.
- האם להפעיל GitHub Pages עבור אתר תמיכה ומדיניות.
