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

import React, { useState, useEffect } from "react";
import { Sheet, SheetContent } from "@/components/ui/sheet";
import { Button } from "@/components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Code, X, Trash2, Terminal, Copy, ExternalLink, Key } from "lucide-react";
import {
  useApiConsoleStore,
  ApiRequest,
  ApiResponse,
} from "@/store/apiConsoleStore";
import JsonViewer from "@/components/JsonViewer";
import { useToast } from "@/custom_hooks/use-toast";

export const DeveloperConsoleButton = () => {
  const { isOpen, setIsOpen } = useApiConsoleStore();

  return (
    <Button
      variant="outline"
      size="sm"
      className="fixed right-4 bottom-4 z-30 shadow-md border-primary"
      onClick={() => setIsOpen(!isOpen)}
    >
      <Terminal className="h-4 w-4 mr-2" />
      <span>Console</span>
    </Button>
  );
};

interface RequestCardProps {
  request: ApiRequest;
  response?: ApiResponse;
}

const RequestCard: React.FC<RequestCardProps> = ({ request, response }) => {
  const { toast } = useToast();
  const [expanded, setExpanded] = useState(false);

  const copyToClipboard = (data: any, type: string) => {
    navigator.clipboard.writeText(JSON.stringify(data, null, 2));
    toast({
      title: "Copied to clipboard",
      description: `${type} data has been copied to your clipboard.`,
    });
  };

  const getStatusColor = (status: number) => {
    if (status >= 200 && status < 300) return "text-green-500";
    if (status >= 300 && status < 400) return "text-yellow-500";
    if (status >= 400) return "text-red-500";
    return "text-gray-500";
  };

  return (
    <div
      className={`border rounded-md mb-2 p-2 ${
        expanded ? "bg-accent/30" : "bg-background"
      } hover:bg-accent/10 transition-all`}
    >
      <div
        className="flex justify-between items-center cursor-pointer"
        onClick={() => setExpanded(!expanded)}
      >
        <div className="flex items-center space-x-2">
          <span className="font-mono text-xs bg-primary/10 px-2 py-0.5 rounded">
            {request.method}
          </span>
          <span className="text-sm font-semibold truncate max-w-[150px] sm:max-w-[250px]">
            {new URL(request.url).pathname}
          </span>
        </div>

        <div className="flex items-center space-x-2">
          {response && (
            <span
              className={`text-xs font-mono ${getStatusColor(response.status)}`}
            >
              {response.status}
            </span>
          )}
          <span className="text-xs text-muted-foreground">
            {new Date(request.timestamp).toLocaleTimeString()}
          </span>
        </div>
      </div>

      {expanded && (
        <div className="mt-6 space-y-2 text-xs">
          <div className="flex justify-between">
            <h4 className="font-semibold">Request</h4>
            <Button
              variant="ghost"
              size="sm"
              className="h-6 w-6 p-0"
              onClick={(e) => {
                e.stopPropagation();
                copyToClipboard(request, "Request");
              }}
            >
              <Copy className="h-3 w-3" />
            </Button>
          </div>

          <div className="font-mono break-all bg-muted p-1 rounded text-xs">
            {request.url}
          </div>

          {request.body && (
            <div className="border rounded bg-accent/10 p-2">
              <JsonViewer data={request.body} />
            </div>
          )}

          {response && response.data && (
            <>
              <div className="flex justify-between pt-4">
                <h4 className="font-semibold">Response</h4>
              </div>

                <div className="border rounded bg-accent/10 p-2">
                <JsonViewer
                  data={
                  typeof response.data === "string"
                    ? JSON.parse(response.data)
                    : response.data
                  }
                />
                </div>
            </>
          )}
        </div>
      )}
    </div>
  );
};

export const DeveloperConsole: React.FC = () => {
  const { isOpen, setIsOpen, requests, responses, clearLogs } =
    useApiConsoleStore();
  const [activeTab, setActiveTab] = useState("all");
  const [authToken, setAuthToken] = useState<any>(null);

  useEffect(() => {
    const storedToken = sessionStorage.getItem("fhirAuthToken");
    if (storedToken) {
      setAuthToken(JSON.parse(storedToken));
    }
  }, [activeTab]);

  // Find matching responses for each request
  const getResponseForRequest = (requestId: string) => {
    return responses.find((response) => response.requestId === requestId);
  };

  return (
    <Sheet open={isOpen} onOpenChange={setIsOpen}>
      <SheetContent
        className="w-full sm:w-[600px] sm:max-w-md p-0"
        side="right"
      >
        <div className="flex flex-col h-full">
          <div className="p-4 border-b flex justify-between items-center bg-accent/10">
            <div className="flex items-center gap-2">
              <Code className="h-5 w-5" />
              <h2 className="text-lg font-semibold">Developer Console</h2>
            </div>
            <div className="flex gap-2">
              <Button
                variant="ghost"
                size="icon"
                onClick={clearLogs}
                title="Clear logs"
              >
                <Trash2 className="h-4 w-4" />
              </Button>
              <Button
                variant="ghost"
                size="icon"
                onClick={() => setIsOpen(false)}
                title="Close"
              >
                <X className="h-4 w-4" />
              </Button>
            </div>
          </div>

          <Tabs
            defaultValue="all"
            value={activeTab}
            onValueChange={setActiveTab}
            className="flex-1 flex flex-col"
          >
            <div className="px-4 pt-2">
              <TabsList className="w-full">
                <TabsTrigger value="all" className="flex-1">
                  All
                </TabsTrigger>
                <TabsTrigger value="requests" className="flex-1">
                  Requests
                </TabsTrigger>
                <TabsTrigger value="auth" className="flex-1">
                  Auth
                </TabsTrigger>
              </TabsList>
            </div>

            <div className="flex-1 overflow-hidden">
              <TabsContent value="all" className="h-full m-0">
                <ScrollArea className="h-full max-h-[calc(100vh-10rem)] px-4 py-2">
                  {requests.length === 0 ? (
                    <div className="flex flex-col justify-center items-center h-full text-muted-foreground">
                      <Terminal className="h-10 w-10 mb-4 opacity-20" />
                      <p>No API calls captured yet.</p>
                    </div>
                  ) : (
                    requests.map((request) => (
                      <RequestCard
                        key={request.id}
                        request={request}
                        response={getResponseForRequest(request.id)}
                      />
                    ))
                  )}
                </ScrollArea>
              </TabsContent>

              <TabsContent value="auth" className="h-full m-0">
                <ScrollArea className="h-full max-h-[calc(100vh-10rem)] px-4 py-2">
                  {!authToken ? (
                    <div className="text-center py-8 text-muted-foreground">
                      <Key className="h-10 w-10 mx-auto mb-2 opacity-20" />
                      <p>No authentication token available.</p>
                    </div>
                  ) : (
                    <div className="border rounded-md p-4 space-y-4">
                      <div className="flex items-center justify-between">
                        <h3 className="text-sm font-semibold">Auth Token</h3>
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => {
                            navigator.clipboard.writeText(
                              JSON.stringify(authToken, null, 2)
                            );
                          }}
                          className="h-6"
                        >
                          <Copy className="h-3 w-3" />
                        </Button>
                      </div>
                      <div className="border rounded bg-accent/10 p-2">
                        <JsonViewer data={authToken} />
                      </div>
                    </div>
                  )}
                </ScrollArea>
              </TabsContent>

              <TabsContent value="requests" className="h-full m-0">
                <ScrollArea className="h-full max-h-[calc(100vh-10rem)] px-4 py-2">
                  {requests.length === 0 ? (
                    <div className="text-center py-8 text-muted-foreground">
                      <ExternalLink className="h-10 w-10 mx-auto mb-2 opacity-20" />
                      <p>No requests captured yet.</p>
                    </div>
                  ) : (
                    requests.map((request) => (
                      <RequestCard key={request.id} request={request} />
                    ))
                  )}
                </ScrollArea>
              </TabsContent>
            </div>
          </Tabs>
        </div>
      </SheetContent>
    </Sheet>
  );
};
