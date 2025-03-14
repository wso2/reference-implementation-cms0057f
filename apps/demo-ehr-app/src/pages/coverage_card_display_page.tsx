// Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import { useContext } from "react";
import { ExpandedContext } from "../utils/expanded_context";
import { useSelector } from "react-redux";
import { SystemActionComponent } from "../components/systemAction";
import { useAuth } from "../components/AuthProvider";
import { Navigate } from "react-router-dom";

export function CoverageCardDisplayPage() {
  const { isAuthenticated } = useAuth();
  const { expanded } = useContext(ExpandedContext);

  const cdsResponse = useSelector((state: any) => state.cdsResponse);
  console.log("cdsResponse in CoverageCardDisplayPage");
  console.log(cdsResponse);

  return isAuthenticated ? (
    <div>
      <div
        style={{
          display: "grid",
          gridTemplateColumns: expanded ? "repeat(1, 1fr)" : "repeat(2, 1fr)",
          gap: "20px",
          columnGap: "10px",
          justifyItems: "center",
        }}
      >
        {/* {cdsResponse.cards.map((coverageCard) => (
          <CoverageCard
            indicator={coverageCard.indicator as CDSIndicator}
            links={coverageCard.links}
            source={coverageCard.source}
            suggestions={coverageCard.suggestions?.map((suggestion) => ({
              ...suggestion,
              actions: suggestion.actions.map((action) => ({
                ...action,
                type: action.type as CDSActionType,
              })),
            }))}
            selectorBehavior={
              coverageCard.selectorBehavior as CDSSelectorBehavior
            }
            summary={coverageCard.summary}
            detail={coverageCard.detail}
            isPreview={isPreview}
          />
        ))} */}
        {cdsResponse.systemActions &&
          cdsResponse.systemActions[0].resource &&
          cdsResponse.systemActions[0].resource.extension && (
            <SystemActionComponent
              extension={cdsResponse.systemActions[0].resource.extension}
            />
          )}
      </div>
    </div>
  ) : (
    <Navigate to="/" replace />
  );
}
