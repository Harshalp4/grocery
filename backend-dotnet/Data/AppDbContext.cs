using FarmFresh.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace FarmFresh.Api.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Category> Categories => Set<Category>();
    public DbSet<Product> Products => Set<Product>();
    public DbSet<ProductVariant> ProductVariants => Set<ProductVariant>();
    public DbSet<Review> Reviews => Set<Review>();
    public DbSet<ComboPack> ComboPacks => Set<ComboPack>();
    public DbSet<SubscriptionPlan> SubscriptionPlans => Set<SubscriptionPlan>();
    public DbSet<BasketLine> BasketLines => Set<BasketLine>();
    public DbSet<User> Users => Set<User>();
    public DbSet<Address> Addresses => Set<Address>();
    public DbSet<DeliverySlot> DeliverySlots => Set<DeliverySlot>();
    public DbSet<ServiceableArea> ServiceableAreas => Set<ServiceableArea>();
    public DbSet<DeliveryPartner> DeliveryPartners => Set<DeliveryPartner>();
    public DbSet<OtpCode> OtpCodes => Set<OtpCode>();
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<OrderEvent> OrderEvents => Set<OrderEvent>();
    public DbSet<ReturnRequest> ReturnRequests => Set<ReturnRequest>();
    public DbSet<OrderItem> OrderItems => Set<OrderItem>();
    public DbSet<Coupon> Coupons => Set<Coupon>();
    public DbSet<CartItem> CartItems => Set<CartItem>();
    public DbSet<WishlistItem> WishlistItems => Set<WishlistItem>();
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<DeviceToken> DeviceTokens => Set<DeviceToken>();
    public DbSet<SupportTicket> SupportTickets => Set<SupportTicket>();
    public DbSet<Banner> Banners => Set<Banner>();
    public DbSet<AdminUser> AdminUsers => Set<AdminUser>();
    public DbSet<PartnerDevice> PartnerDevices => Set<PartnerDevice>();
    public DbSet<PartnerLocation> PartnerLocations => Set<PartnerLocation>();

    protected override void OnModelCreating(ModelBuilder b)
    {
        b.Entity<Category>().HasIndex(c => c.Slug).IsUnique();

        // Product.categorySlug references Category.slug (a non-PK principal key).
        b.Entity<Product>()
            .HasOne(p => p.Category)
            .WithMany(c => c.Products)
            .HasForeignKey(p => p.CategorySlug)
            .HasPrincipalKey(c => c.Slug)
            .OnDelete(DeleteBehavior.Restrict);

        b.Entity<ProductVariant>()
            .HasOne(v => v.Product)
            .WithMany(p => p.Variants)
            .HasForeignKey(v => v.ProductId)
            .OnDelete(DeleteBehavior.Cascade);
        b.Entity<ProductVariant>().HasIndex(v => v.ProductId);

        b.Entity<Review>()
            .HasOne(r => r.Product)
            .WithMany(p => p.Reviews)
            .HasForeignKey(r => r.ProductId)
            .OnDelete(DeleteBehavior.Restrict);

        b.Entity<User>().HasIndex(u => u.Phone).IsUnique();

        b.Entity<Address>()
            .HasOne(a => a.User)
            .WithMany(u => u.Addresses)
            .HasForeignKey(a => a.UserId)
            .OnDelete(DeleteBehavior.Cascade);
        b.Entity<Address>().HasIndex(a => a.UserId);

        b.Entity<ServiceableArea>().HasIndex(a => a.Pincode).IsUnique();

        b.Entity<OtpCode>().HasIndex(o => o.Phone);

        b.Entity<Coupon>().HasIndex(c => c.Code).IsUnique();

        b.Entity<CartItem>()
            .HasOne(ci => ci.User)
            .WithMany(u => u.CartItems)
            .HasForeignKey(ci => ci.UserId)
            .OnDelete(DeleteBehavior.Cascade);
        b.Entity<CartItem>().HasIndex(ci => ci.UserId);

        b.Entity<WishlistItem>()
            .HasOne(w => w.User)
            .WithMany(u => u.Wishlist)
            .HasForeignKey(w => w.UserId)
            .OnDelete(DeleteBehavior.Cascade);
        b.Entity<WishlistItem>().HasIndex(w => new { w.UserId, w.ProductId }).IsUnique();

        b.Entity<Notification>()
            .HasOne(n => n.User)
            .WithMany(u => u.Notifications)
            .HasForeignKey(n => n.UserId)
            .OnDelete(DeleteBehavior.Cascade);
        b.Entity<Notification>().HasIndex(n => n.UserId);

        b.Entity<DeviceToken>()
            .HasOne(t => t.User)
            .WithMany(u => u.DeviceTokens)
            .HasForeignKey(t => t.UserId)
            .OnDelete(DeleteBehavior.Cascade);
        b.Entity<DeviceToken>().HasIndex(t => t.Token).IsUnique();

        b.Entity<SupportTicket>()
            .HasOne(s => s.User)
            .WithMany(u => u.SupportTickets)
            .HasForeignKey(s => s.UserId)
            .OnDelete(DeleteBehavior.Cascade);
        b.Entity<SupportTicket>().HasIndex(s => s.UserId);

        b.Entity<AdminUser>().HasIndex(a => a.Email).IsUnique();

        b.Entity<DeliveryPartner>().HasIndex(p => p.Phone).IsUnique();
        b.Entity<PartnerDevice>()
            .HasOne(d => d.Partner).WithMany(p => p.Devices)
            .HasForeignKey(d => d.PartnerId).OnDelete(DeleteBehavior.Cascade);
        b.Entity<PartnerDevice>().HasIndex(d => d.Token).IsUnique();
        b.Entity<PartnerLocation>()
            .HasOne(l => l.Partner).WithMany(p => p.Locations)
            .HasForeignKey(l => l.PartnerId).OnDelete(DeleteBehavior.Cascade);
        b.Entity<PartnerLocation>().HasIndex(l => new { l.PartnerId, l.RecordedAt });
        b.Entity<PartnerLocation>().HasIndex(l => l.OrderId);

        b.Entity<Order>().HasIndex(o => o.Code).IsUnique();
        b.Entity<Order>()
            .HasOne(o => o.User)
            .WithMany(u => u.Orders)
            .HasForeignKey(o => o.UserId)
            .OnDelete(DeleteBehavior.Restrict);
        b.Entity<Order>()
            .HasOne(o => o.DeliveryPartner)
            .WithMany(p => p.Orders)
            .HasForeignKey(o => o.DeliveryPartnerId)
            .OnDelete(DeleteBehavior.SetNull);

        b.Entity<OrderItem>()
            .HasOne(i => i.Order)
            .WithMany(o => o.Items)
            .HasForeignKey(i => i.OrderId)
            .OnDelete(DeleteBehavior.Cascade);

        b.Entity<OrderEvent>()
            .HasOne(e => e.Order)
            .WithMany(o => o.Events)
            .HasForeignKey(e => e.OrderId)
            .OnDelete(DeleteBehavior.Cascade);
        b.Entity<OrderEvent>().HasIndex(e => e.OrderId);

        b.Entity<ReturnRequest>()
            .HasOne(r => r.Order)
            .WithOne(o => o.ReturnRequest)
            .HasForeignKey<ReturnRequest>(r => r.OrderId)
            .OnDelete(DeleteBehavior.Cascade);
        b.Entity<ReturnRequest>().HasIndex(r => r.OrderId).IsUnique();
    }

    // Mirror Prisma @updatedAt: stamp UpdatedAt on modified Orders/ReturnRequests.
    public override int SaveChanges()
    {
        StampTimestamps();
        return base.SaveChanges();
    }

    public override Task<int> SaveChangesAsync(CancellationToken ct = default)
    {
        StampTimestamps();
        return base.SaveChangesAsync(ct);
    }

    private void StampTimestamps()
    {
        var now = DateTime.UtcNow;
        foreach (var e in ChangeTracker.Entries())
        {
            if (e.State != EntityState.Modified) continue;
            if (e.Entity is Order o) o.UpdatedAt = now;
            else if (e.Entity is ReturnRequest r) r.UpdatedAt = now;
            else if (e.Entity is SupportTicket s) s.UpdatedAt = now;
        }
    }
}
