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

import React, { useState } from "react";
import { ChevronRight, ChevronDown, Copy, Check } from "lucide-react";
import { Button } from "@/components/ui/button";

interface JsonViewerProps {
  data: any;
  initialExpanded?: boolean;
}

const JsonViewer: React.FC<JsonViewerProps> = ({ data, initialExpanded = true }) => {
  const [copiedText, setCopiedText] = useState<boolean>(false);
  
  const handleCopyToClipboard = () => {
    navigator.clipboard.writeText(JSON.stringify(data, null, 2));
    setCopiedText(true);
    setTimeout(() => setCopiedText(false), 2000);
  };

  return (
    <div className="relative rounded-lg overflow-hidden font-mono text-sm">
      <div className="absolute top-2 right-2 z-10">
        <Button 
          variant="ghost" 
          size="sm" 
          className="h-8 w-8 p-0" 
          onClick={handleCopyToClipboard}
        >
          {copiedText ? (
            <Check className="h-4 w-4 text-green-500" />
          ) : (
            <Copy className="h-4 w-4" />
          )}
        </Button>
      </div>
      <div className="p-4 overflow-x-auto">
        <JsonNode data={data} name="payload" level={0} initialExpanded={initialExpanded} />
      </div>
    </div>
  );
};

interface JsonNodeProps {
  data: any;
  name: string;
  level: number;
  initialExpanded: boolean;
}

const JsonNode: React.FC<JsonNodeProps> = ({ data, name, level, initialExpanded }) => {
  const [isExpanded, setIsExpanded] = useState<boolean>(
    initialExpanded && level < 2
  );
  
  const toggleExpanded = () => {
    setIsExpanded(!isExpanded);
  };
  
  const indent = { paddingLeft: `${level * 1.5}rem` };

  // Render different UI based on data type
  if (data === null) {
    return (
      <div className="py-1" style={indent}>
        <span className="text-muted-foreground">{name}: </span>
        <span className="text-yellow-600">null</span>
      </div>
    );
  }

  if (typeof data === "undefined") {
    return (
      <div className="py-1" style={indent}>
        <span className="text-muted-foreground">{name}: </span>
        <span className="text-yellow-600">undefined</span>
      </div>
    );
  }

  if (typeof data === "boolean") {
    return (
      <div className="py-1" style={indent}>
        <span className="text-muted-foreground">{name}: </span>
        <span className="text-blue-600">{data.toString()}</span>
      </div>
    );
  }

  if (typeof data === "number") {
    return (
      <div className="py-1" style={indent}>
        <span className="text-muted-foreground">{name}: </span>
        <span className="text-green-600">{data}</span>
      </div>
    );
  }

  if (typeof data === "string") {
    return (
      <div className="py-1" style={indent}>
        <span className="text-muted-foreground">{name}: </span>
        <span className="text-red-600">"{data}"</span>
      </div>
    );
  }

  if (Array.isArray(data)) {
    if (data.length === 0) {
      return (
        <div className="py-1" style={indent}>
          <span className="text-muted-foreground">{name}: </span>
          <span>[]</span>
        </div>
      );
    }

    return (
      <div className="py-1">
        <div
          className="cursor-pointer hover:bg-accent/50 rounded flex items-center"
          style={indent}
          onClick={toggleExpanded}
        >
          {isExpanded ? (
            <ChevronDown className="h-3 w-3 mr-1 inline-block text-muted-foreground" />
          ) : (
            <ChevronRight className="h-3 w-3 mr-1 inline-block text-muted-foreground" />
          )}
          <span className="">{name}: </span>
          <span className="ml-1 text-muted-foreground">Array[{data.length}]</span>
        </div>
        {isExpanded && (
          <div>
            {data.map((item, index) => (
              <JsonNode
                key={`${name}-${index}`}
                data={item}
                name={`${index}`}
                level={level + 1}
                initialExpanded={initialExpanded}
              />
            ))}
          </div>
        )}
      </div>
    );
  }

  // Object
  const keys = Object.keys(data);
  if (keys.length === 0) {
    return (
      <div className="py-1" style={indent}>
        <span className="text-muted-foreground">{name}: </span>
        <span>{"{}"}</span>
      </div>
    );
  }

  return (
    <div className="py-1">
      <div
        className="cursor-pointer hover:bg-accent/50 rounded flex items-center"
        style={indent}
        onClick={toggleExpanded}
      >
        {isExpanded ? (
          <ChevronDown className="h-3 w-3 mr-1 inline-block text-muted-foreground" />
        ) : (
          <ChevronRight className="h-3 w-3 mr-1 inline-block text-muted-foreground" />
        )}
        <span className="">{name}: </span>
        <span className="ml-1 text-muted-foreground">Object{`{${keys.length}}`}</span>
      </div>
      {isExpanded && (
        <div>
          {keys.map((key) => (
            <JsonNode
              key={`${name}-${key}`}
              data={data[key]}
              name={key}
              level={level + 1}
              initialExpanded={initialExpanded}
            />
          ))}
        </div>
      )}
    </div>
  );
};

export default JsonViewer;
