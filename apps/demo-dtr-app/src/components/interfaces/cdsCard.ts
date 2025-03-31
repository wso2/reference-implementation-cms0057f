// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com).
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

interface Coding {
    id?: string;
    extension?: object;
    system?: string;
    version?: string;
    code?: string;
    display?: string;
    userSelected?: boolean;
  }
  
  enum ActionType {
    CREATE = "create",
    UPDATE = "update",
    DELETE = "delete",
  }
  
  interface Action {
    type: ActionType;
    description: string;
    resource?: object;
    resourceId?: string;
  }
  
  interface Source {
    label: string;
    url?: string;
    icon?: string;
    topic?: Coding;
  }
  
  interface Suggestion {
    label: string;
    uuid?: string;
    isRecommended?: boolean;
    actions?: Action[];
  }
  
  enum LinkType {
    ABSOLUTE = "absolute",
    SMART = "smart",
  }
  
  export interface CdsLink {
    label: string;
    url: string;
    type: LinkType;
    appContext?: string;
  }
  
  export interface CdsCard {
    uuid?: string;
    summary: string;
    detail?: string;
    indicator: string;
    source: Source;
    suggestions?: Suggestion[];
    selectionBehavior?: string;
    overrideReason?: Coding[];
    links?: CdsLink[];
  }
  
  export interface CdsResponse {
    cards: CdsCard[];
    systemActions?: Action[];
  }
