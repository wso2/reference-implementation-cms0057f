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

import {
  Card,
  CardHeader,
  CardMedia,
  CardContent,
  Collapse,
  Grid,
} from "@mui/material";
import { useNavigate } from "react-router-dom";
import { DRUG_DETAILS } from "../constants/data";
import { Box } from "@mui/material";
import { useContext } from "react";
import { ExpandedContext } from "../utils/expanded_context";
import { useDispatch } from "react-redux";
import { updateCdsHook, resetCdsRequest } from "../redux/cdsRequestSlice";

interface CardData {
  name: string;
  imagePath: string;
  description: string;
}

const CardComponent = ({ data }: { data: CardData }) => {
  const navigate = useNavigate();

  const dispatch = useDispatch();

  dispatch(resetCdsRequest());
  dispatch(updateCdsHook("order-select"));

  const handleDrugClick = (drugName: string) => {
    navigate(`/dashboard/drug-order/${drugName}`);
  };

  return (
    <Grid item xs={12} sm={4}>
      <Card onClick={() => handleDrugClick(data.name)}>
        <Box
          display="flex"
          justifyContent="center"
          alignItems="center"
          flexDirection="column"
          marginTop="15px"
        >
          <CardMedia>
            <img
              src="/drug_1.png"
              alt={data.name}
              style={{
                height: "150px",
                width: "auto",
                objectFit: "contain",
              }}
            />
          </CardMedia>
          <CardHeader title={data.name} style={{ cursor: "pointer" }} />
          <Collapse in={true} timeout="auto" unmountOnExit>
            <CardContent style={{ marginRight: 20, textAlign: "justify" }}>
              {data.description}
            </CardContent>
          </Collapse>
        </Box>
      </Card>
    </Grid>
  );
};

export default function DrugOrderPage() {
  const { expanded } = useContext(ExpandedContext);
  return (
    <div
      style={{
        display: "grid",
        gridTemplateColumns: expanded ? "repeat(1, 1fr)" : "repeat(3, 1fr)",
        gap: "20px",
        marginLeft: expanded ? "10vw" : "2vw",
        marginRight: expanded ? "10vw" : 0,
      }}
    >
      {DRUG_DETAILS.map((item, index) => (
        <CardComponent key={index} data={item} />
      ))}
    </div>
  );
}
