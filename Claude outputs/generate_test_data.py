#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
מחולל נתוני טסט לטבלת public.gaps (פרויקט "פועלי בניין").

מייצר N פערים אקראיים (ברירת מחדל 100), עם ערכים שתואמים בדיוק
לרשימות ולאילוצים שמוגדרים באתר (index.html) ובסכימה (schema.sql):
  - company   : אחת מ-COMPANIES
  - location  : אחת מ-LOCATIONS
  - status    : אחת מ-STATUSES (עם משקלים ריאליים - רוב "טרם הועלה"/"בטיפול")
  - priority  : אחת מ-PRIORITIES
  - opened_at : תאריך אקראי ב-180 הימים האחרונים
  - note      : לרוב ריק, ולעיתים הערה קצרה; במיקומים שדורשים פירוט
                (שביל / דשא) כמעט תמיד יש הערה מפרטת - בדיוק כמו
                שה-UI של האתר "מבקש" (NEEDS_DETAIL) דרך ה-placeholder.

הרצה:
    python3 generate_test_data.py            # 100 שורות, פלט: insert_test_data.sql
    python3 generate_test_data.py --n 50      # מספר שורות אחר
    python3 generate_test_data.py --seed 42   # תוצאה קבועה/ניתנת לשחזור
    python3 generate_test_data.py --csv       # פלט נוסף כ-CSV (ליבוא דרך Table Editor)

הפלט הוא קובץ SQL אחד (insert_test_data.sql) שמדביקים ב-Supabase
SQL Editor ומריצים - בדיוק כמו זרימת העבודה המתוארת ב-README לגבי
schema.sql. הרצה בטוחה: כל שורה מקבלת id חדש (gen_random_uuid), אז
אין קונפליקט עם נתונים קיימים.
"""

import argparse
import csv
import random
from datetime import date, timedelta

# ---- אותם ערכים בדיוק כמו ב-index.html (COMPANIES / LOCATIONS / ...) ----
COMPANIES = ["בשור", "צין", "פארן", "תמר", "רמון"]
LOCATIONS = [
    "מגורי בנות", "מגורי בנים", "פינת ישיבה", "פינת פריסה",
    "דקצ\"ו (דק קמנים)", "שביל", "דשא", "פינת גלח\"צ", "מתחם קמנים",
    "ספריית קמנים", "רחבת רמון", "פינת קק\"ס", "פינת עישון",
]
NEEDS_DETAIL = {"שביל": "איזה שביל?", "דשא": "איזה דשא?"}
STATUSES = ["טרם הועלה", "בטיפול", "טופל"]
STATUS_WEIGHTS = [0.45, 0.35, 0.20]          # יותר "טרם הועלה", כמו במציאות
PRIORITIES = ["גבוה", "בינוני", "נמוך"]
PRIORITY_WEIGHTS = [0.25, 0.5, 0.25]

# תיאורי פערים לדוגמה - תחזוקה/בינוי, רלוונטי לדומיין של האתר
GAP_TEMPLATES = [
    "תאורה לא עובדת", "נורה שרופה", "דלת שבורה", "דלת לא נסגרת טוב",
    "חלון סדוק", "חלון בלי רשת יתושים", "ברז דולף", "אין מים חמים",
    "ריצוף סדוק", "בור בריצוף", "חוט חשמל חשוף", "שקע חשמל לא תקין",
    "מזגן לא עובד", "מזגן מרעיש", "אסלה סתומה", "אסלה שבורה",
    "כיור שבור", "כיור סתום", "משטח בטון סדוק", "גדר פרוצה",
    "תאורת חוץ כבויה", "עמוד תאורה כבוי", "נזילת מים מהתקרה",
    "מדרגה רופפת", "מעקה רופף", "ספסל שבור", "פח אשפה חסר",
    "פח אשפה מלא וגדוש", "שולחן שבור", "ארון בגדים שבור",
    "מיטה שבורה", "מזרן קרוע", "מקלחת סתומה", "מקלחת בלי לחץ מים",
    "אין תאורת חירום", "כביש גישה עם בור", "שילוט חסר",
    "שילוט לא ברור", "רשת צל קרועה", "מדחום/גלאי עשן לא תקין",
    "ברזייה לא עובדת", "מזגן מטפטף", "צנרת חשופה", "קיר עם רטיבות",
    "צבע מתקלף", "משקוף עקום", "ידית דלת שבורה", "מנעול תקול",
    "וילון/תריס שבור", "כבל חשמל מונח על הרצפה",
]

# הערות אפשריות (חלקן כלליות, חלקן "מענה" ל-NEEDS_DETAIL)
GENERIC_NOTES = [
    "", "", "", "",  # לרוב אין הערה
    "דחוף לטפל השבוע", "דווח כבר פעם קודמת", "צריך להזמין קבלן חיצוני",
    "מחכים לאישור תקציב", "חומרים בדרך", "יטופל בסבב הבא",
]
PATH_DETAILS = ["השביל ליד מגורי בנים", "השביל מול חדר האוכל",
                "השביל בין הפינות", "השביל לכיוון הרחבה"]
GRASS_DETAILS = ["הדשא מול הבנות", "הדשא ליד פינת הישיבה",
                  "הדשא באזור הרחבה", "הדשא בכניסה למתחם"]


def random_date(days_back=180):
    return date.today() - timedelta(days=random.randint(0, days_back))


def make_note(location):
    if location == "שביל":
        return random.choice(PATH_DETAILS)
    if location == "דשא":
        return random.choice(GRASS_DETAILS)
    return random.choice(GENERIC_NOTES)


def gen_rows(n):
    rows = []
    for _ in range(n):
        location = random.choice(LOCATIONS)
        rows.append({
            "company": random.choice(COMPANIES),
            "gap": random.choice(GAP_TEMPLATES),
            "location": location,
            "status": random.choices(STATUSES, weights=STATUS_WEIGHTS, k=1)[0],
            "priority": random.choices(PRIORITIES, weights=PRIORITY_WEIGHTS, k=1)[0],
            "opened_at": random_date().isoformat(),
            "note": make_note(location),
        })
    return rows


def sql_escape(v):
    return "'" + str(v).replace("'", "''") + "'"


def write_sql(rows, path):
    values = []
    for r in rows:
        values.append(
            "  (" +
            ", ".join([
                sql_escape(r["company"]),
                sql_escape(r["gap"]),
                sql_escape(r["location"]),
                sql_escape(r["status"]),
                sql_escape(r["priority"]),
                sql_escape(r["opened_at"]),
                sql_escape(r["note"]),
            ]) + ")"
        )
    sql = (
        "-- נתוני טסט אקראיים ל-public.gaps (פועלי בניין)\n"
        "-- נוצר אוטומטית ע\"י generate_test_data.py — {n} שורות\n"
        "-- הדביקו והריצו ב-Supabase: SQL Editor > New query > Run\n\n"
        "insert into public.gaps (company, gap, location, status, priority, opened_at, note)\n"
        "values\n" + ",\n".join(values) + ";\n"
    ).format(n=len(rows))
    with open(path, "w", encoding="utf-8") as f:
        f.write(sql)


def write_csv(rows, path):
    with open(path, "w", encoding="utf-8-sig", newline="") as f:
        w = csv.writer(f)
        w.writerow(["company", "gap", "location", "status", "priority", "opened_at", "note"])
        for r in rows:
            w.writerow([r["company"], r["gap"], r["location"], r["status"],
                        r["priority"], r["opened_at"], r["note"]])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--n", type=int, default=100, help="כמות פערים לייצר")
    ap.add_argument("--seed", type=int, default=None, help="seed לתוצאה שמישחזרת")
    ap.add_argument("--csv", action="store_true", help="לייצא גם CSV")
    ap.add_argument("--out", default="insert_test_data.sql", help="שם קובץ ה-SQL")
    args = ap.parse_args()

    if args.seed is not None:
        random.seed(args.seed)

    rows = gen_rows(args.n)
    write_sql(rows, args.out)
    print("נכתב: {} ({} שורות)".format(args.out, len(rows)))

    if args.csv:
        csv_path = args.out.rsplit(".", 1)[0] + ".csv"
        write_csv(rows, csv_path)
        print("נכתב: {} ({} שורות)".format(csv_path, len(rows)))


if __name__ == "__main__":
    main()
