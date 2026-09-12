# פועלי בניין — הקמה על Supabase ו‑GitHub Pages

שני קבצים בלבד: `index.html` (האתר) ו‑`schema.sql` (מסד הנתונים).

---

## 1. Supabase

1. היכנסו ל‑supabase.com, צרו פרויקט חדש, בחרו אזור **Europe (Frankfurt)** — הכי קרוב.
2. בתפריט הצד: **SQL Editor › New query**. הדביקו את כל התוכן של `schema.sql`, לחצו **Run**.
3. **Authentication › Providers › Email**: כבו את **Enable email signups**. זה מונע ממישהו זר לפתוח לעצמו חשבון.
4. **Authentication › Users › Add user › Create new user**: צרו חשבון לכל איש צוות. סמנו **Auto Confirm User** כדי לדלג על אימות מייל.
5. **Project Settings › API**: העתיקו את שני הערכים —
   - `Project URL`
   - `anon` `public` key

---

## 2. חיבור האתר

פתחו את `index.html`, ובראש בלוק ה‑`<script>` החליפו את שתי השורות:

```js
var SUPABASE_URL      = "https://YOUR-PROJECT-REF.supabase.co";
var SUPABASE_ANON_KEY = "YOUR-ANON-PUBLIC-KEY";
```

המפתח הזה נועד להיות גלוי בקוד הדף — הוא לא סוד. מה שמגן על הנתונים הוא ה‑RLS
שהגדרתם בשלב 1: בלי התחברות, השאילתה חוזרת ריקה.

---

## 3. GitHub Pages

```bash
git init
git add index.html schema.sql README.md
git commit -m "פועלי בניין"
git branch -M main
git remote add origin https://github.com/USERNAME/REPO.git
git push -u origin main
```

ואז ב‑GitHub: **Settings › Pages › Source: Deploy from a branch**, ענף `main`, תיקייה `/ (root)`, ו‑**Save**.
תוך דקה־שתיים האתר יעלה בכתובת `https://USERNAME.github.io/REPO/`.

**חשוב:** ריפו ציבורי חושף את הקוד, לא את הנתונים. אם אתם מעדיפים, ריפו פרטי
עובד עם GitHub Pages בחשבונות Pro/Team.

---

## 4. אחרי העלייה

חזרו ל‑Supabase, **Authentication › URL Configuration**, והוסיפו את כתובת ה‑Pages
תחת **Site URL**.

---

## שינויים נפוצים

**הוספת מיקום** — בקובץ `index.html`, במערך `LOCATIONS`.
**החלפת פלוגה** — במערך `COMPANIES`.
**מיקום שדורש פירוט בהערות** — במפה `NEEDS_DETAIL`, בסגנון `"דשא":"איזה דשא?"`.
**שינוי רמות עדיפות** — במערך `PRIORITIES` (ותיוג הצבעים במפה `PCLS`).

אחרי כל שינוי: `git add . && git commit -m "..." && git push` — ה‑Pages מתעדכן לבד.

---

## עדכון סכימה — עדיפות ותאריך פתיחה

אם ה‑DB שלכם הוקם לפני התוספת הזו, חוזרים ל‑Supabase **SQL Editor** ומריצים שוב
את כל `schema.sql` (הריצה בטוחה לחזרה — `add column if not exists`).
בלי הריצה הזו, הוספה/עריכה של פערים תיכשל כי העמודות `priority` ו‑`opened_at`
לא קיימות עדיין בטבלה.

**עריכת פער מלאה** — לחיצה על אייקון העיפרון (✎) בשורה פותחת חלון שבו ניתן
לראות ולערוך את כל שדות הפער במקום אחד.
**מיון וסינון** — בכותרות "תאריך פתיחה" / "סטטוס" / "עדיפות" יש כפתורי מיון (⇅),
ובשורת הכלים יש גם סינון לפי מיקום ועדיפות ותפריט "מיין לפי".
**הוספת פער** — כפתור "+ פער חדש" בשורת הכלים העליונה פותח פופאפ להזנת פער חדש.

---

## עדכון סכימה — Changelog לכל פער

תכונה חדשה: לחיצה על אייקון השעון (🕐) בשורה פותחת חלון עם כל פרטי הפער
**והיסטוריית כל שינוי** שנעשה בו (מי, מתי, איזה שדה, מה היה ומה הפך להיות).
זה דורש טבלה חדשה במסד הנתונים — `gap_changes`.

אם ה‑DB שלכם הוקם לפני התוספת הזו: חוזרים ל‑Supabase **SQL Editor** ומריצים שוב
את כל `schema.sql` (בטוח לחזרה — `create table if not exists`). בלי הריצה הזו,
הוספה/עריכה של פער עדיין תעבוד, אבל פתיחת חלון ה-Changelog תיכשל בטעינת ההיסטוריה.

---

## עדכון סכימה — מי פתח את הפער

תכונה חדשה: במודל הוספה/עריכה של פער אפשר לרשום את שם ומספר הטלפון של מי
שפתח אותו (שני השדות רשותיים — `opened_by_name`, `opened_by_phone`). הפרטים
מוצגים במסך "פרטי הפער" (🕐), והטלפון מוצג כקישור שאפשר ללחוץ עליו כדי
להתקשר ישירות מהנייד.

אם ה‑DB שלכם הוקם לפני התוספת הזו: חוזרים ל‑Supabase **SQL Editor** ומריצים שוב
את כל `schema.sql` (בטוח לחזרה — `add column if not exists`).

---

## גיבוי

בתוך האתר יש **ייצוא לאקסל** שמוריד CSV.
לגיבוי מלא: ב‑Supabase, **Table Editor › gaps › Export › CSV**.
