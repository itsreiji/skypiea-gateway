"use client";

import useAuthorized from "@/app/(dashboard)/hooks/useAuthorized";
import useTeams from "@/app/(dashboard)/hooks/useTeams";
import { useState } from "react";
import ModelsAndEndpointsView from "@/app/(dashboard)/models-and-endpoints/ModelsAndEndpointsView";

const ModelsAndEndpointsPage = () => {
  const { token, accessToken, userRole, userId, premiumUser } = useAuthorized();
  const [keys, setKeys] = useState<null | any[]>([]);
  const [modelData, setModelData] = useState<{ data: any[] }>({ data: [] });

  const { teams } = useTeams();

  return (
    <ModelsAndEndpointsView
      accessToken={accessToken}
      token={token}
      userRole={userRole}
      userID={userId}
      modelData={modelData}
      keys={keys}
      setModelData={setModelData}
      premiumUser={premiumUser}
      teams={teams}
    />
  );
};

export default ModelsAndEndpointsPage;
