using Mx.BaseService.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;

namespace Mx.BaseService.Infrastructure
{
    public class DefaultMxIdentity : IMxIdentity
    {
        private readonly ClaimsIdentity _identity;
        private readonly string _name;

        public DefaultMxIdentity(ClaimsIdentity identity)
        {
            _identity = identity;
            _name = identity.Name;
        }
        public string Name => _name;
        public IEnumerable<Claim> Claims => _identity.Claims;
    }
}
