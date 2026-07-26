using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace FarmFresh.Api.Migrations
{
    /// <inheritdoc />
    public partial class PartnerAuthAndTracking : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "AssignedAt",
                table: "Orders",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "CodCollected",
                table: "Orders",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<DateTime>(
                name: "DeliveredAt",
                table: "Orders",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "DeliveryNote",
                table: "Orders",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "DeliveryOtp",
                table: "Orders",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "DeliveryOtpAttempts",
                table: "Orders",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<DateTime>(
                name: "DeliveryOtpSentAt",
                table: "Orders",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "DestLat",
                table: "Orders",
                type: "double precision",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "DestLng",
                table: "Orders",
                type: "double precision",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "FailureReason",
                table: "Orders",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "PickedUpAt",
                table: "Orders",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ProofPhotoUrl",
                table: "Orders",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "DeliveryPartners",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<double>(
                name: "LastLat",
                table: "DeliveryPartners",
                type: "double precision",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "LastLng",
                table: "DeliveryPartners",
                type: "double precision",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "LastLocationAt",
                table: "DeliveryPartners",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "LastLoginAt",
                table: "DeliveryPartners",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "MustChangePassword",
                table: "DeliveryPartners",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "OnDuty",
                table: "DeliveryPartners",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "PasswordHash",
                table: "DeliveryPartners",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<int>(
                name: "TokenVersion",
                table: "DeliveryPartners",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "VehicleNumber",
                table: "DeliveryPartners",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "VehicleType",
                table: "DeliveryPartners",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Zone",
                table: "DeliveryPartners",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "Lat",
                table: "Addresses",
                type: "double precision",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "Lng",
                table: "Addresses",
                type: "double precision",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "PartnerDevices",
                columns: table => new
                {
                    Id = table.Column<string>(type: "text", nullable: false),
                    PartnerId = table.Column<string>(type: "text", nullable: false),
                    Token = table.Column<string>(type: "text", nullable: false),
                    Platform = table.Column<string>(type: "text", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PartnerDevices", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PartnerDevices_DeliveryPartners_PartnerId",
                        column: x => x.PartnerId,
                        principalTable: "DeliveryPartners",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PartnerLocations",
                columns: table => new
                {
                    Id = table.Column<string>(type: "text", nullable: false),
                    PartnerId = table.Column<string>(type: "text", nullable: false),
                    OrderId = table.Column<string>(type: "text", nullable: true),
                    Lat = table.Column<double>(type: "double precision", nullable: false),
                    Lng = table.Column<double>(type: "double precision", nullable: false),
                    Accuracy = table.Column<double>(type: "double precision", nullable: true),
                    Speed = table.Column<double>(type: "double precision", nullable: true),
                    Heading = table.Column<double>(type: "double precision", nullable: true),
                    RecordedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PartnerLocations", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PartnerLocations_DeliveryPartners_PartnerId",
                        column: x => x.PartnerId,
                        principalTable: "DeliveryPartners",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_DeliveryPartners_Phone",
                table: "DeliveryPartners",
                column: "Phone",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_PartnerDevices_PartnerId",
                table: "PartnerDevices",
                column: "PartnerId");

            migrationBuilder.CreateIndex(
                name: "IX_PartnerDevices_Token",
                table: "PartnerDevices",
                column: "Token",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_PartnerLocations_OrderId",
                table: "PartnerLocations",
                column: "OrderId");

            migrationBuilder.CreateIndex(
                name: "IX_PartnerLocations_PartnerId_RecordedAt",
                table: "PartnerLocations",
                columns: new[] { "PartnerId", "RecordedAt" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "PartnerDevices");

            migrationBuilder.DropTable(
                name: "PartnerLocations");

            migrationBuilder.DropIndex(
                name: "IX_DeliveryPartners_Phone",
                table: "DeliveryPartners");

            migrationBuilder.DropColumn(
                name: "AssignedAt",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "CodCollected",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "DeliveredAt",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "DeliveryNote",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "DeliveryOtp",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "DeliveryOtpAttempts",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "DeliveryOtpSentAt",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "DestLat",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "DestLng",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "FailureReason",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "PickedUpAt",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "ProofPhotoUrl",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "DeliveryPartners");

            migrationBuilder.DropColumn(
                name: "LastLat",
                table: "DeliveryPartners");

            migrationBuilder.DropColumn(
                name: "LastLng",
                table: "DeliveryPartners");

            migrationBuilder.DropColumn(
                name: "LastLocationAt",
                table: "DeliveryPartners");

            migrationBuilder.DropColumn(
                name: "LastLoginAt",
                table: "DeliveryPartners");

            migrationBuilder.DropColumn(
                name: "MustChangePassword",
                table: "DeliveryPartners");

            migrationBuilder.DropColumn(
                name: "OnDuty",
                table: "DeliveryPartners");

            migrationBuilder.DropColumn(
                name: "PasswordHash",
                table: "DeliveryPartners");

            migrationBuilder.DropColumn(
                name: "TokenVersion",
                table: "DeliveryPartners");

            migrationBuilder.DropColumn(
                name: "VehicleNumber",
                table: "DeliveryPartners");

            migrationBuilder.DropColumn(
                name: "VehicleType",
                table: "DeliveryPartners");

            migrationBuilder.DropColumn(
                name: "Zone",
                table: "DeliveryPartners");

            migrationBuilder.DropColumn(
                name: "Lat",
                table: "Addresses");

            migrationBuilder.DropColumn(
                name: "Lng",
                table: "Addresses");
        }
    }
}
