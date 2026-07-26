namespace FarmFresh.Api.Models;

// EF Core entities — a faithful port of prisma/schema.prisma. IDs that used
// Prisma `cuid()` default to a GUID here (opaque strings; clients don't parse
// them). Products/combos/subscriptions keep their explicit string ids.

public class Category
{
    public string Id { get; set; } = Guid.NewGuid().ToString("N");
    public string Slug { get; set; } = "";
    public string Name { get; set; } = "";
    public string Emoji { get; set; } = "";
    public int SortOrder { get; set; }
    public List<Product> Products { get; set; } = new();
}

public class Product
{
    public string Id { get; set; } = "";
    public string Name { get; set; } = "";
    public string Source { get; set; } = "";
    public string PackedDate { get; set; } = "";
    public int Price { get; set; }
    public int MarketPrice { get; set; }
    public string Grade { get; set; } = "";
    public string Tags { get; set; } = "";          // comma-separated: best,fresh,premium
    public string? HarvestMonth { get; set; }
    public string? PackSize { get; set; }
    public string Nutrition { get; set; } = "{}";    // JSON string
    public string? ImageUrl { get; set; }
    public int Stock { get; set; } = 20;
    public string CategorySlug { get; set; } = "";
    public Category? Category { get; set; }
    public List<Review> Reviews { get; set; } = new();
    public List<ProductVariant> Variants { get; set; } = new();
}

public class ProductVariant
{
    public string Id { get; set; } = Guid.NewGuid().ToString("N");
    public string ProductId { get; set; } = "";
    public Product? Product { get; set; }
    public string Label { get; set; } = "";
    public int Price { get; set; }
    public int MarketPrice { get; set; }
    public int Stock { get; set; } = 20;
    public int SortOrder { get; set; }
}

public class Review
{
    public string Id { get; set; } = Guid.NewGuid().ToString("N");
    public string ProductId { get; set; } = "";
    public Product? Product { get; set; }
    public string Initials { get; set; } = "";
    public string Author { get; set; } = "";
    public string Area { get; set; } = "";
    public int Rating { get; set; }
    public string Text { get; set; } = "";
}

public class ComboPack
{
    public string Id { get; set; } = "";
    public string Name { get; set; } = "";
    public string Type { get; set; } = "";       // family | health | festival
    public int Price { get; set; }
    public string Size { get; set; } = "";
    public string Duration { get; set; } = "";
    public string Items { get; set; } = "";
    public string SavingsNote { get; set; } = "";
}

public class SubscriptionPlan
{
    public string Id { get; set; } = "";
    public string Name { get; set; } = "";
    public string Description { get; set; } = "";
    public string PriceLabel { get; set; } = "";
}

public class BasketLine
{
    public string Id { get; set; } = Guid.NewGuid().ToString("N");
    public string List { get; set; } = "";       // "kirana" | "repeat"
    public string Name { get; set; } = "";
    public string Quantity { get; set; } = "";
    public string PriceLabel { get; set; } = "";
    public int SortOrder { get; set; }
}

// A discount coupon. `type` is "percent" (value = %) or "flat" (value = ₹).
public class Coupon
{
    public string Id { get; set; } = Guid.NewGuid().ToString("N");
    public string Code { get; set; } = "";           // stored/compared uppercase
    public string Type { get; set; } = "flat";       // percent | flat
    public int Value { get; set; }                    // % if percent, ₹ if flat
    public int MinOrder { get; set; }                 // minimum item total to qualify
    public int MaxDiscount { get; set; }              // cap for percent coupons (0 = no cap)
    public DateTime? ValidFrom { get; set; }
    public DateTime? ValidTo { get; set; }
    public int UsageLimit { get; set; }               // total redemptions allowed (0 = unlimited)
    public int PerUserLimit { get; set; }             // per-user redemptions (0 = unlimited)
    public int TimesUsed { get; set; }
    public bool Active { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

// A customer support ticket.
public class SupportTicket
{
    public string Id { get; set; } = Guid.NewGuid().ToString("N");
    public string UserId { get; set; } = "";
    public User? User { get; set; }
    public string? OrderId { get; set; }        // optional: ticket about an order
    public string Subject { get; set; } = "";
    public string Message { get; set; } = "";
    public string Status { get; set; } = "open"; // open | resolved | closed
    public string? Reply { get; set; }           // admin reply
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}

// A home-screen promo banner (managed from the admin CMS).
public class Banner
{
    public string Id { get; set; } = Guid.NewGuid().ToString("N");
    public string Title { get; set; } = "";
    public string Subtitle { get; set; } = "";
    public string? ImageUrl { get; set; }
    public string? ActionType { get; set; }      // category | product | url
    public string? ActionValue { get; set; }     // slug / id / url
    public bool Active { get; set; } = true;
    public int SortOrder { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

// A back-office user with a role (in addition to the env bootstrap admin).
public class AdminUser
{
    public string Id { get; set; } = Guid.NewGuid().ToString("N");
    public string Email { get; set; } = "";
    public string PasswordHash { get; set; } = "";  // PBKDF2 "salt.hash"
    public string Role { get; set; } = "staff";      // admin | staff
    public bool Active { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

// A registered customer, identified by phone (verified via OTP).
public class User
{
    public string Id { get; set; } = Guid.NewGuid().ToString("N");
    public string Phone { get; set; } = "";
    public string? Name { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public List<Order> Orders { get; set; } = new();
    public List<Address> Addresses { get; set; } = new();
    public List<CartItem> CartItems { get; set; } = new();
    public List<WishlistItem> Wishlist { get; set; } = new();
    public List<Notification> Notifications { get; set; } = new();
    public List<DeviceToken> DeviceTokens { get; set; } = new();
    public List<SupportTicket> SupportTickets { get; set; } = new();
}

// A persisted in-app notification (the customer's inbox). Order-status changes
// and admin broadcasts fan out to one row per user.
public class Notification
{
    public string Id { get; set; } = Guid.NewGuid().ToString("N");
    public string UserId { get; set; } = "";
    public User? User { get; set; }
    public string Title { get; set; } = "";
    public string Body { get; set; } = "";
    public string Type { get; set; } = "system";  // order | promo | system
    public string? OrderId { get; set; }
    public bool Read { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

// A registered push (FCM) device token for a customer.
public class DeviceToken
{
    public string Id { get; set; } = Guid.NewGuid().ToString("N");
    public string UserId { get; set; } = "";
    public User? User { get; set; }
    public string Token { get; set; } = "";
    public string Platform { get; set; } = "";   // android | ios | web
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

// A product a customer saved to their wishlist / favorites.
public class WishlistItem
{
    public string Id { get; set; } = Guid.NewGuid().ToString("N");
    public string UserId { get; set; } = "";
    public User? User { get; set; }
    public string ProductId { get; set; } = "";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

// A line in a signed-in customer's persistent cart. `qty` is the unit count;
// `price` is the unit price. Same product+variant is merged into one row.
public class CartItem
{
    public string Id { get; set; } = Guid.NewGuid().ToString("N");
    public string UserId { get; set; } = "";
    public User? User { get; set; }
    public string? ProductId { get; set; }
    public string? VariantId { get; set; }
    public string Name { get; set; } = "";
    public string Quantity { get; set; } = "";   // pack label, e.g. "1 kg"
    public string PriceLabel { get; set; } = "";
    public int Price { get; set; }                // unit price
    public int Qty { get; set; } = 1;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public class Address
{
    public string Id { get; set; } = Guid.NewGuid().ToString("N");
    public string UserId { get; set; } = "";
    public User? User { get; set; }
    public string Label { get; set; } = "Home";
    public string Line { get; set; } = "";
    public string? Area { get; set; }
    public string? City { get; set; }
    public string? Pincode { get; set; }
    public bool IsDefault { get; set; }
    public double? Lat { get; set; }   // optional map coords (progressive enhancement)
    public double? Lng { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public class DeliverySlot
{
    public string Id { get; set; } = Guid.NewGuid().ToString("N");
    public string Label { get; set; } = "";
    public bool Active { get; set; } = true;
    public int SortOrder { get; set; }
}

public class ServiceableArea
{
    public string Id { get; set; } = Guid.NewGuid().ToString("N");
    public string Pincode { get; set; } = "";
    public string? Area { get; set; }
    public string? City { get; set; }
    public string EtaLabel { get; set; } = "Next day";
    public bool Active { get; set; } = true;
}

public class DeliveryPartner
{
    public string Id { get; set; } = Guid.NewGuid().ToString("N");
    public string Name { get; set; } = "";
    public string Phone { get; set; } = "";            // login identifier (unique, digits)
    public bool Active { get; set; } = true;            // false ⇒ cannot log in, tokens revoked

    // credentials (admin-issued)
    public string PasswordHash { get; set; } = "";      // PBKDF2 via Services/Passwords.cs
    public bool MustChangePassword { get; set; } = true;
    public int TokenVersion { get; set; }               // bump ⇒ all existing JWTs invalid
    public DateTime? LastLoginAt { get; set; }

    // profile
    public string? VehicleType { get; set; }            // bike | scooter | ev | cycle | van
    public string? VehicleNumber { get; set; }
    public string? Zone { get; set; }

    // live state
    public bool OnDuty { get; set; }
    public double? LastLat { get; set; }
    public double? LastLng { get; set; }
    public DateTime? LastLocationAt { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public List<Order> Orders { get; set; } = new();
    public List<PartnerDevice> Devices { get; set; } = new();
    public List<PartnerLocation> Locations { get; set; } = new();
}

// A rider's FCM token — mirrors the customer DeviceToken table.
public class PartnerDevice
{
    public string Id { get; set; } = Guid.NewGuid().ToString("N");
    public string PartnerId { get; set; } = "";
    public DeliveryPartner? Partner { get; set; }
    public string Token { get; set; } = "";
    public string Platform { get; set; } = "";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

// Location breadcrumbs, written only while on-duty with an active order. Purged after 7 days.
public class PartnerLocation
{
    public string Id { get; set; } = Guid.NewGuid().ToString("N");
    public string PartnerId { get; set; } = "";
    public DeliveryPartner? Partner { get; set; }
    public string? OrderId { get; set; }
    public double Lat { get; set; }
    public double Lng { get; set; }
    public double? Accuracy { get; set; }
    public double? Speed { get; set; }
    public double? Heading { get; set; }
    public DateTime RecordedAt { get; set; } = DateTime.UtcNow;
}

public class OtpCode
{
    public string Id { get; set; } = Guid.NewGuid().ToString("N");
    public string Phone { get; set; } = "";
    public string Code { get; set; } = "";
    public DateTime ExpiresAt { get; set; }
    public bool Consumed { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public class Order
{
    public string Id { get; set; } = Guid.NewGuid().ToString("N");
    public string Code { get; set; } = "";
    public string? UserId { get; set; }
    public User? User { get; set; }
    public string CustomerName { get; set; } = "";
    public string Phone { get; set; } = "";
    public string Address { get; set; } = "";
    public string Slot { get; set; } = "";
    public int ItemTotal { get; set; }
    public int Savings { get; set; }
    public int DeliveryFee { get; set; }
    public int Total { get; set; }
    public string? CouponCode { get; set; }           // applied coupon, if any
    public string PaymentMethod { get; set; } = "";  // upi | card | cod
    public string PaymentStatus { get; set; } = "pending";
    public string? PaymentRef { get; set; }
    public string Status { get; set; } = "placed";
    public string? Eta { get; set; }
    public string? DeliveryPartnerId { get; set; }
    public DeliveryPartner? DeliveryPartner { get; set; }

    // --- delivery / fulfilment (rider app) ---
    public DateTime? AssignedAt { get; set; }
    public DateTime? PickedUpAt { get; set; }
    public DateTime? DeliveredAt { get; set; }
    public string? DeliveryOtp { get; set; }            // 4-digit, minted at out_for_delivery
    public DateTime? DeliveryOtpSentAt { get; set; }
    public int DeliveryOtpAttempts { get; set; }
    public string? ProofPhotoUrl { get; set; }
    public string? DeliveryNote { get; set; }
    public int CodCollected { get; set; }               // ₹ handed over by the customer
    public string? FailureReason { get; set; }
    public double? DestLat { get; set; }                // snapshot of address coords
    public double? DestLng { get; set; }

    public List<OrderItem> Items { get; set; } = new();
    public List<OrderEvent> Events { get; set; } = new();
    public ReturnRequest? ReturnRequest { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}

public class OrderEvent
{
    public string Id { get; set; } = Guid.NewGuid().ToString("N");
    public string OrderId { get; set; } = "";
    public Order? Order { get; set; }
    public string Status { get; set; } = "";
    public string? Note { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public class ReturnRequest
{
    public string Id { get; set; } = Guid.NewGuid().ToString("N");
    public string OrderId { get; set; } = "";
    public Order? Order { get; set; }
    public string? UserId { get; set; }
    public string Reason { get; set; } = "";
    public string Status { get; set; } = "requested";  // requested | approved | rejected | refunded
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}

public class OrderItem
{
    public string Id { get; set; } = Guid.NewGuid().ToString("N");
    public string OrderId { get; set; } = "";
    public Order? Order { get; set; }
    public string? ProductId { get; set; }
    public string? VariantId { get; set; }
    public string Name { get; set; } = "";
    public string Quantity { get; set; } = "";
    public string PriceLabel { get; set; } = "";
    public int Price { get; set; }
    public int Qty { get; set; } = 1;
}
