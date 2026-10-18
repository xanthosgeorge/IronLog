using IronLog.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace IronLog.Persistence;

public class ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : DbContext(options)
{
    public DbSet<User> Users => Set<User>();
    public DbSet<BodyWeightEntry> BodyWeightEntries => Set<BodyWeightEntry>();

    public DbSet<WorkoutSession> WorkoutSessions => Set<WorkoutSession>();

    public DbSet<WorkoutExercise> WorkoutExercises => Set<WorkoutExercise>();

    public DbSet<WorkoutSet> WorkoutSets => Set<WorkoutSet>();

    public DbSet<Exercise> Exercises => Set<Exercise>();

    public DbSet<MuscleGroup> MuscleGroups => Set<MuscleGroup>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        ConfigureUser(modelBuilder);
        modelBuilder.Entity<BodyWeightEntry>(entity =>
        {
            entity.ToTable("body_weight_entries");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.WeightKg).HasPrecision(6, 2);
            entity.HasIndex(x => new { x.UserId, x.RecordedOn });
            entity.HasOne(x => x.User).WithMany(x => x.BodyWeightEntries)
                .HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Cascade);
        });
        ConfigureWorkoutSession(modelBuilder);
        ConfigureWorkoutExercise(modelBuilder);
        ConfigureWorkoutSet(modelBuilder);
        ConfigureExercise(modelBuilder);
        ConfigureMuscleGroup(modelBuilder);
    }

    private static void ConfigureUser(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<User>(entity =>
        {
            entity.ToTable("users");

            entity.HasKey(x => x.Id);

            entity.Property(x => x.FirstName)
                .HasMaxLength(100)
                .IsRequired();

            entity.Property(x => x.LastName)
                .HasMaxLength(100)
                .IsRequired();

            entity.Property(x => x.Email)
                .HasMaxLength(255)
                .IsRequired();

            entity.Property(x => x.PasswordHash)
                .HasMaxLength(500)
                .IsRequired();

            entity.Property(x => x.CreatedAt)
                .IsRequired();

            entity.HasIndex(x => x.Email)
                .IsUnique();
        });
    }

    private static void ConfigureWorkoutSession(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<WorkoutSession>(entity =>
        {
            entity.ToTable("workout_sessions");

            entity.HasKey(x => x.Id);

            entity.Property(x => x.Title)
                .HasMaxLength(200)
                .IsRequired();

            entity.Property(x => x.SessionDate)
                .IsRequired();

            entity.Property(x => x.BodyWeight)
                .HasPrecision(6, 2);

            entity.Property(x => x.TotalLoad)
                .HasPrecision(12, 2)
                .IsRequired();

            entity.Property(x => x.Notes)
                .HasMaxLength(2000);

            entity.Property(x => x.AiSummary)
                .HasMaxLength(4000);

            entity.Property(x => x.CreatedAt)
                .IsRequired();

            entity.HasOne(x => x.User)
                .WithMany(x => x.WorkoutSessions)
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasIndex(x => new { x.UserId, x.SessionDate });
        });
    }

    private static void ConfigureWorkoutExercise(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<WorkoutExercise>(entity =>
        {
            entity.ToTable("workout_exercises");

            entity.HasKey(x => x.Id);

            entity.Property(x => x.Notes)
                .HasMaxLength(2000);

            entity.HasOne(x => x.WorkoutSession)
                .WithMany(x => x.WorkoutExercises)
                .HasForeignKey(x => x.WorkoutSessionId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(x => x.Exercise)
                .WithMany(x => x.WorkoutExercises)
                .HasForeignKey(x => x.ExerciseId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasIndex(x => new { x.WorkoutSessionId, x.OrderIndex })
                .IsUnique();
        });
    }

    private static void ConfigureWorkoutSet(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<WorkoutSet>(entity =>
        {
            entity.ToTable("workout_sets");

            entity.HasKey(x => x.Id);

            entity.Property(x => x.Weight)
                .HasPrecision(8, 2);

            entity.Property(x => x.ResistanceNote)
                .HasMaxLength(1000);

            entity.HasOne(x => x.WorkoutExercise)
                .WithMany(x => x.WorkoutSets)
                .HasForeignKey(x => x.WorkoutExerciseId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasIndex(x => new { x.WorkoutExerciseId, x.SetNumber })
                .IsUnique();
        });
    }

    private static void ConfigureExercise(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Exercise>(entity =>
        {
            entity.ToTable("exercises");

            entity.HasKey(x => x.Id);

            entity.Property(x => x.Name)
                .HasMaxLength(200)
                .IsRequired();

            entity.Property(x => x.EquipmentType)
                .HasMaxLength(100)
                .IsRequired();

            entity.HasOne(x => x.MuscleGroup)
                .WithMany(x => x.Exercises)
                .HasForeignKey(x => x.MuscleGroupId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(x => x.User)
                .WithMany(x => x.Exercises)
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasIndex(x => new { x.UserId, x.Name })
                .IsUnique();
        });
    }

    private static void ConfigureMuscleGroup(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<MuscleGroup>(entity =>
        {
            entity.ToTable("muscle_groups");

            entity.HasKey(x => x.Id);

            entity.Property(x => x.Name)
                .HasMaxLength(100)
                .IsRequired();

            entity.Property(x => x.Description)
                .HasMaxLength(1000);

            entity.HasOne(x => x.User)
                .WithMany(x => x.MuscleGroups)
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasIndex(x => new { x.UserId, x.Name })
                .IsUnique();
        });
    }
}
