using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace IronLog.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddUserOwnedCatalogData : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                DELETE FROM workout_sets;
                DELETE FROM workout_exercises;
                DELETE FROM workout_sessions;
                DELETE FROM exercises;
                DELETE FROM muscle_groups;
                DELETE FROM users;
                """);

            migrationBuilder.DropIndex(
                name: "IX_muscle_groups_Name",
                table: "muscle_groups");

            migrationBuilder.DropIndex(
                name: "IX_exercises_Name",
                table: "exercises");

            migrationBuilder.AddColumn<Guid>(
                name: "UserId",
                table: "muscle_groups",
                type: "uuid",
                nullable: false);

            migrationBuilder.AddColumn<Guid>(
                name: "UserId",
                table: "exercises",
                type: "uuid",
                nullable: false);

            migrationBuilder.CreateIndex(
                name: "IX_muscle_groups_UserId_Name",
                table: "muscle_groups",
                columns: new[] { "UserId", "Name" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_exercises_UserId_Name",
                table: "exercises",
                columns: new[] { "UserId", "Name" },
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_exercises_users_UserId",
                table: "exercises",
                column: "UserId",
                principalTable: "users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_muscle_groups_users_UserId",
                table: "muscle_groups",
                column: "UserId",
                principalTable: "users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_exercises_users_UserId",
                table: "exercises");

            migrationBuilder.DropForeignKey(
                name: "FK_muscle_groups_users_UserId",
                table: "muscle_groups");

            migrationBuilder.DropIndex(
                name: "IX_muscle_groups_UserId_Name",
                table: "muscle_groups");

            migrationBuilder.DropIndex(
                name: "IX_exercises_UserId_Name",
                table: "exercises");

            migrationBuilder.DropColumn(
                name: "UserId",
                table: "muscle_groups");

            migrationBuilder.DropColumn(
                name: "UserId",
                table: "exercises");

            migrationBuilder.CreateIndex(
                name: "IX_muscle_groups_Name",
                table: "muscle_groups",
                column: "Name",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_exercises_Name",
                table: "exercises",
                column: "Name",
                unique: true);
        }
    }
}
