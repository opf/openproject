import { useEffect, useState } from 'react';
import { canCreateWorkPackages, fetchCreateWorkPackagePermission } from '../services/openProjectApi';

export function useCanCreateWorkPackages():boolean {
  const [allowed, setAllowed] = useState(canCreateWorkPackages);

  useEffect(() => {
    let active = true;
    void fetchCreateWorkPackagePermission().then((permitted) => {
      if (active) setAllowed(permitted);
    });
    return () => { active = false; };
  }, []);

  return allowed;
}
