# HBMS — Database Diagram

**Database**: `hbmsdb` · **Engine**: InnoDB · **Charset**: utf8mb4 · **DBMS**: MySQL 8.0

---

## Entity-Relationship Diagram

> Render with any Mermaid-compatible viewer (GitHub, VS Code Mermaid Preview extension, etc.)

```mermaid
erDiagram

    tblcategory {
        int         ID              PK  "AUTO_INCREMENT"
        varchar120  CategoryName
        mediumtext  Description
        int         Price               "Price per night"
        timestamp   Date                "DEFAULT CURRENT_TIMESTAMP"
    }

    tblroom {
        int         ID              PK  "AUTO_INCREMENT"
        int         RoomType        FK  "→ tblcategory.ID"
        varchar200  RoomName
        int         MaxAdult
        int         MaxChild
        mediumtext  RoomDesc
        int         NoofBed
        varchar200  Image               "Image filename"
        varchar200  RoomFacility        "Comma-separated facility IDs"
        timestamp   CreationDate        "DEFAULT CURRENT_TIMESTAMP"
    }

    tbluser {
        int         ID              PK  "AUTO_INCREMENT"
        varchar200  FullName
        bigint      MobileNumber
        varchar120  Email
        varchar120  Password            "Hashed"
        timestamp   RegDate             "DEFAULT CURRENT_TIMESTAMP"
    }

    tblbooking {
        int         ID              PK  "AUTO_INCREMENT"
        int         RoomId          FK  "→ tblroom.ID"
        int         UserID          FK  "→ tbluser.ID"
        varchar120  BookingNumber       "Unique reference"
        varchar120  IDType              "Voter Card / Passport etc."
        varchar50   Gender
        mediumtext  Address
        varchar200  CheckinDate
        varchar200  CheckoutDate
        timestamp   BookingDate         "DEFAULT CURRENT_TIMESTAMP"
        varchar50   Remark
        varchar50   Status              "Approved / Cancelled / Pending"
        timestamp   UpdationDate
    }

    tbladmin {
        int         ID              PK  "AUTO_INCREMENT"
        varchar120  AdminName
        varchar200  UserName
        bigint      MobileNumber
        varchar200  Email
        varchar200  Password            "Hashed"
        timestamp   AdminRegdate        "DEFAULT CURRENT_TIMESTAMP"
    }

    tblfacility {
        int         ID              PK  "AUTO_INCREMENT"
        varchar200  FacilityTitle
        mediumtext  Description
        varchar200  Image               "Image filename"
        timestamp   CreationDate        "DEFAULT CURRENT_TIMESTAMP"
    }

    tblcontact {
        int         ID              PK  "AUTO_INCREMENT"
        varchar200  Name
        bigint      MobileNumber
        varchar200  Email
        mediumtext  Message
        timestamp   EnquiryDate         "DEFAULT CURRENT_TIMESTAMP"
        int         IsRead              "0 = Unread, 1 = Read"
    }

    tblpage {
        int         ID              PK  "AUTO_INCREMENT"
        varchar120  PageType            "aboutus / contactus"
        varchar200  PageTitle
        mediumtext  PageDescription
        varchar120  Email
        bigint      MobileNumber
        timestamp   UpdationDate
    }

    %% ─── RELATIONSHIPS ───
    tblcategory ||--o{ tblroom    : "categorizes (RoomType)"
    tblroom     ||--o{ tblbooking : "booked via (RoomId)"
    tbluser     ||--o{ tblbooking : "makes (UserID)"
```

---

## Tables at a Glance

| Table | Rows (seed) | Purpose |
|---|---|---|
| `tblcategory` | 5 | Room types — Single, Double, Triple, Quad, Queen |
| `tblroom` | 6 | Individual rooms belonging to a category |
| `tbluser` | 4 | Registered customer accounts |
| `tblbooking` | 5 | Room reservations made by customers |
| `tbladmin` | 1 | Hotel admin accounts |
| `tblfacility` | 8 | Hotel amenities shown on the website |
| `tblcontact` | 1 | Enquiries submitted via the contact form |
| `tblpage` | 2 | CMS content — About Us & Contact Us |

---

## Relationships

```
tblcategory ──< tblroom        (one category → many rooms)
    tblroom ──< tblbooking     (one room → many bookings)
    tbluser ──< tblbooking     (one user → many bookings)
```

> **Note:** Foreign keys are enforced at the application layer (PHP/PDO), not as MySQL `FOREIGN KEY` constraints in the schema.

---

## Standalone Tables (no FK links)

| Table | Reason |
|---|---|
| `tbladmin` | Separate auth system; not linked to `tbluser` |
| `tblfacility` | Referenced loosely via `tblroom.RoomFacility` (comma-separated IDs, no FK) |
| `tblcontact` | Anonymous enquiries — no `UserID` link |
| `tblpage` | Static CMS content — no relational links |

---

## Soft Link: `tblroom.RoomFacility`

`tblroom.RoomFacility` stores a **comma-separated list of `tblfacility.ID` values**
(e.g., `"1,3,5"`). This is a denormalised many-to-many shortcut — there is no
junction table. The application parses the string to display facility icons per room.

---

## Booking Status Values

| Status | Meaning |
|---|---|
| `Approved` | Admin has confirmed the booking |
| `Cancelled` | Booking was cancelled (by user or admin) |
| *(pending/empty)* | Awaiting admin review |

---

## Connection Details (Docker)

| Setting | Value |
|---|---|
| Host | `db` (Docker service name) |
| Port | `3306` |
| Database | `hbmsdb` |
| User | `root` |
| Method | PDO (PHP) |
| phpMyAdmin | `localhost:8081` |
