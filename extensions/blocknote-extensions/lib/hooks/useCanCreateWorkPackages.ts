import { useEffect, useState } from 'react';
import { canCreateWorkPackages, whenCreateWorkPackagePermissionKnown } from '../services/openProjectApi';

export function useCanCreateWorkPackages():boolean {
  const [allowed, setAllowed] = useState(canCreateWorkPackages);

  useEffect(() => {
    let active = true;
    void whenCreateWorkPackagePermissionKnown().then((permitted) => {
      if (active) setAllowed(permitted);
    });
    return () => { active = false; };
  }, []);

  return allowed;
}
