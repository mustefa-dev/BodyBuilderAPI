using System;

namespace BodyBuilderAPI.Entities
{
    public class User
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public string FullName { get; set; }
        public string PhoneNumber { get; set; }
        public string PasswordHash { get; set; }
        public bool IsActive { get; set; } = true;
        public string Role { get; set; } = "User"; // User or Admin
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
