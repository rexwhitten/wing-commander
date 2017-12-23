using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Security.Claims;

namespace Mx.BaseService.Interfaces
{
    public interface IMxIdentity
    {
        IEnumerable<Claim> Claims { get; }
        String Name { get; }
    }
}
