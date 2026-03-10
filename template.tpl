___INFO___

{
  "type": "TAG",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "Meta CAPI Tag - TRKKN version",
  "brand": {
    "id": "trakkengmbh",
    "displayName": "TRKKN",
    "thumbnail": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAFYAAABWCAMAAABiiJHFAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAtUExURTI0OFVWWudaWdwLCkBCRWVmaX+Ag2lrbuEsK4+Qk4iJi5aYmkdJTHN0dwAAAF0JZa0AAAAPdFJOU///////////////////ANTcmKEAAAAJcEhZcwAADsMAAA7DAcdvqGQAAACTSURBVFhH7djLCsMgGAXh9H73/R83A55NJcS0IKUw30p+dJaCTmWIqUxdu+yN/aHLLMzCLMyizR5PC87pxRfZS46uMQuzMAuzMAuz+LPstYvsEGZhFmZhFsOyeSBUt4w/ds/NWpHNqtpy3y4yC7MwC7MwC7P4SXbL99oj4zfPBKo2u6j5DHxlvMIszMIszILsAKXMco/kEnH0rWUAAAAASUVORK5CYII="
  },
  "categories": ["ADVERTISING", "CONVERSIONS", "MARKETING"],
  "description": "Enhanced the original Meta CAPI Tag by adding event and parameter mappings and more. Built on the official Facebook template (version 1.0.0, released July 23, 2025). For additional details, refer to the notes.",
  "containerContexts": ["SERVER"]
}

___NOTES___

Based on the official template: https://github.com/facebookincubator/ConversionsAPI-Tag-for-GoogleTagManager version: 1.0.0 (July 23rd, 2025)
Added Features:
1. anonymisation of IP by default
2. custom event mapping
3. custom parameter mapping. 
4. Support for FB Repost
5. Support for multiple Pixel Ids

With this template you do not need to follow FB namings.
___SANDBOXED_JS_FOR_SERVER___

// Sandbox Javascript imports
const getAllEventData = require("getAllEventData");
const getType = require("getType");
const sendHttpRequest = require("sendHttpRequest");
const JSON = require("JSON");
const Math = require("Math");
const getTimestampMillis = require("getTimestampMillis");
const sha256Sync = require("sha256Sync");
const toBase64 = require("toBase64");
const fromBase64 = require("fromBase64");
const getCookieValues = require("getCookieValues");
const setCookie = require("setCookie");
const generateRandom = require("generateRandom");
const decodeUriComponent = require("decodeUriComponent");
const parseUrl = require("parseUrl");
const computeEffectiveTldPlusOne = require("computeEffectiveTldPlusOne");
const log = require("logToConsole");

// Constants
const API_ENDPOINT = "https://graph.facebook.com";
const API_VERSION = "v16.0";
const PARTNER_AGENT = "trkkn-2.0.0";
const GTM_EVENT_MAPPINGS = {
  add_payment_info: "AddPaymentInfo",
  add_to_cart: "AddToCart",
  add_to_wishlist: "AddToWishlist",
  "gtm.dom": "PageView",
  page_view: "PageView",
  purchase: "Purchase",
  search: "Search",
  begin_checkout: "InitiateCheckout",
  generate_lead: "Lead",
  view_item: "ViewContent",
  sign_up: "CompleteRegistration",
};

const eventModel = getAllEventData();

/* TRKKN Custom 1*/
/* HOW TO UPDATE
main thing is to add FB_PARAMS_MAPPINGS in original 

*/

if (data.customEventMapping) {
  for (let i = 0; i < data.customEventMapping.length; i += 1) {
    if (valueIsFilled(data.customEventMapping[i].event_name)) {
      GTM_EVENT_MAPPINGS[data.customEventMapping[i].event_name] =
        data.customEventMapping[i].event_name_facebook;
    }
  }
}

const FB_PARAMS_MAPPINGS = {};
if (data.fbParameterMapping) {
  for (let i = 0; i < data.fbParameterMapping.length; i += 1) {
    if (valueIsFilled(data.fbParameterMapping[i].fb_parameter_value)) {
      FB_PARAMS_MAPPINGS[data.fbParameterMapping[i].fb_parameter_key] =
        data.fbParameterMapping[i].fb_parameter_value;
    }
  }
}

/*trkkn custom 1 end*/

function isAlreadyHashed(input) {
  return input && input.match("^[A-Fa-f0-9]{64}$") != null;
}

function setFbCookie(name, value, expire) {
  setCookie(name, value, {
    domain: "auto",
    path: "/",
    samesite: "Lax",
    secure: true,
    "max-age": expire || 7776000, // default to 90 days
    httpOnly: false,
  });
}

function setHttpOnlyCookie(name, value, expire) {
  setCookie(name, value, {
    domain: "auto",
    path: "/",
    samesite: "strict",
    secure: true,
    "max-age": expire || 7776000, // default to 90 days
    httpOnly: true,
  });
}

function getFbcValue() {
  let fbc = eventModel["x-fb-ck-fbc"] || getCookieValues("_fbc", true)[0];
  const url = eventModel.page_location;
  const subDomainIndex = url ? computeEffectiveTldPlusOne(url).split(".").length - 1 : 1;
  const parsedUrl = parseUrl(url);
  if (parsedUrl && parsedUrl.searchParams.fbclid) {
    fbc =
      "fb." +
      subDomainIndex +
      "." +
      getTimestampMillis() +
      "." +
      decodeUriComponent(parsedUrl.searchParams.fbclid);
  }

  return fbc;
}

function hashFunction(input) {
  const type = getType(input);
  if (type == "undefined" || input == "undefined") {
    return undefined;
  }

  if (input == null || isAlreadyHashed(input)) {
    return input;
  }

  return sha256Sync(input.trim().toLowerCase(), { outputEncoding: "hex" });
}

function getContentFromItems(items) {
  return items.map((item) => {
    return {
      id: item.item_id || item.item_name || undefined,
      item_price: item.price || undefined,
      quantity: item.quantity || undefined,
    };
  });
}

function getMetaEventName(gtmEventName) {
  //TRKKN changed
  return eventModel.fbEventName || GTM_EVENT_MAPPINGS[gtmEventName] || gtmEventName;
}

const event = {};
event.event_name = getMetaEventName(eventModel.event_name);
event.event_time = eventModel.event_time || Math.round(getTimestampMillis() / 1000);
event.event_id = FB_PARAMS_MAPPINGS.event_id || eventModel.event_id;
event.event_source_url = eventModel.page_location;
if (eventModel.action_source || data.actionSource) {
  event.action_source = eventModel.action_source ? eventModel.action_source : data.actionSource;
}
event.referrer_url = FB_PARAMS_MAPPINGS.page_referrer || eventModel.page_referrer;

event.user_data = {};
// Default Tag Parameters
event.user_data.client_ip_address = getIPAddress();
event.user_data.client_user_agent = FB_PARAMS_MAPPINGS.user_agent || eventModel.user_agent;

if (data.userDataAllowed === "allow") {
  // Commmon Event Schema Parameters
  const userEmail =
    FB_PARAMS_MAPPINGS.user_email ||
    eventModel["x-fb-ud-em"] ||
    (eventModel.user_data != null ? eventModel.user_data.email_address : undefined) ||
    (eventModel.user_data != null ? eventModel.user_data.sha256_email_address : undefined);
  event.user_data.em = hashFunction(userEmail);

  let normalizedPhoneNumber = null;
  if (
    FB_PARAMS_MAPPINGS.user_phone_number ||
    (eventModel.user_data &&
      (eventModel.user_data.phone_number || eventModel.user_data.sha256_phone_number))
  ) {
    const phoneNM =
      FB_PARAMS_MAPPINGS.user_phone_number ||
      eventModel.user_data.phone_number ||
      eventModel.user_data.sha256_phone_number;
    normalizedPhoneNumber = phoneNM
      .replace("+", "")
      .replace("-", "")
      .replace(" ", "")
      .replace("(", "")
      .replace(")", "");
    normalizedPhoneNumber = hashFunction(normalizedPhoneNumber);
  }
  event.user_data.ph =
    eventModel["x-fb-ud-ph"] || (normalizedPhoneNumber != null ? normalizedPhoneNumber : undefined);

  const addressData =
    eventModel.user_data != null && eventModel.user_data.address != null
      ? eventModel.user_data.address
      : {};
  event.user_data.fn = eventModel["x-fb-ud-fn"] || hashFunction(addressData.first_name);
  event.user_data.ln = eventModel["x-fb-ud-ln"] || hashFunction(addressData.last_name);
  event.user_data.ct = eventModel["x-fb-ud-ct"] || hashFunction(addressData.city);
  event.user_data.st = eventModel["x-fb-ud-st"] || hashFunction(addressData.region);
  event.user_data.zp = eventModel["x-fb-ud-zp"] || hashFunction(addressData.postal_code);
  event.user_data.country =
    FB_PARAMS_MAPPINGS.country ||
    eventModel["x-fb-ud-country"] ||
    hashFunction(addressData.country);

  // Conversions API Specific Parameters
  event.user_data.ge = FB_PARAMS_MAPPINGS.user_gender || eventModel["x-fb-ud-ge"];
  event.user_data.db = FB_PARAMS_MAPPINGS.user_date_birth || eventModel["x-fb-ud-db"];
}
event.user_data.external_id = FB_PARAMS_MAPPINGS.external_id || eventModel["x-fb-ud-external_id"];
event.user_data.subscription_id =
  FB_PARAMS_MAPPINGS.subscription_id || eventModel["x-fb-ud-subscription_id"];
event.user_data.fbp =
  eventModel["x-fb-ck-fbp"] || getCookieValues("_fbp", true)[0] || generateFBP();
event.user_data.fbc = getFbcValue();
event.user_data.fb_login_id =
  eventModel["x-fb-ud-fb-login-id"] ||
  (eventModel.user_data != null && eventModel.user_data.fb_login_id != null
    ? eventModel.user_data.fb_login_id
    : undefined);

event.custom_data = {};

/* TRKKN Custom facebook event repost*/
/* HOW TO UPDATE
  main thing is to add FB_PARAMS_MAPPINGS in original 
*/
if (data.processTrkknRepostHits) {
  let fbData =
    data.repostDataSource === "default" ? eventModel.fbData || "{}" : data.repostDataSource;
  if (getType(fbData) !== "string") {
    log("ERROR: data for repost must be a string, Got: " + getType(fbData) + ". will be resetted.");
    fbData = "{}";
  }
  const repostFbData = JSON.parse(fbData);

  if (repostFbData) {
    for (const property in repostFbData) {
      if (valueIsFilled(repostFbData[property])) {
        event.custom_data[property] = repostFbData[property];
        FB_PARAMS_MAPPINGS[property] = repostFbData[property];
      }
    }
  }
}

/* TRKKN Custom facebook event repost END*/

/* TRKKN Custom 1.5*/
/* HOW TO UPDATE
  main thing is to add FB_PARAMS_MAPPINGS in original 
*/
if (data.customParameterMapping) {
  for (let i = 0; i < data.customParameterMapping.length; i += 1) {
    if (valueIsFilled(data.customParameterMapping[i].fb_cust_parameter_value)) {
      event.custom_data[data.customParameterMapping[i].fb_cust_parameter_key] =
        data.customParameterMapping[i].fb_cust_parameter_value;
    }
  }
}

/* TRKKN Custom 1.5 END*/

event.custom_data.currency = FB_PARAMS_MAPPINGS.currency || eventModel.currency;
event.custom_data.value = FB_PARAMS_MAPPINGS.value || eventModel.value;
event.custom_data.search_string = FB_PARAMS_MAPPINGS.search_string || eventModel.search_term;
event.custom_data.order_id = FB_PARAMS_MAPPINGS.order_id || eventModel.transaction_id;
event.custom_data.content_category =
  FB_PARAMS_MAPPINGS.content_category || eventModel["x-fb-cd-content_category"];
event.custom_data.content_ids = FB_PARAMS_MAPPINGS.content_ids || eventModel["x-fb-cd-content_ids"];
event.custom_data.content_name =
  FB_PARAMS_MAPPINGS.content_name || eventModel["x-fb-cd-content_name"];
event.custom_data.content_type =
  FB_PARAMS_MAPPINGS.content_type || eventModel["x-fb-cd-content_type"];
const invalidString = "[object Object]";
event.custom_data.contents =
  FB_PARAMS_MAPPINGS.contents ||
  (eventModel["x-fb-cd-contents"] != null &&
  eventModel["x-fb-cd-contents"].indexOf(invalidString) == 0
    ? null
    : typeof eventModel["x-fb-cd-contents"] == "string"
    ? JSON.parse(eventModel["x-fb-cd-contents"])
    : eventModel["x-fb-cd-contents"]) ||
  (eventModel.items != null ? getContentFromItems(eventModel.items) : undefined);

if (event.custom_data.contents && !event.custom_data.content_type) {
  event.custom_data.content_type = "product";
}

const customProperties =
  eventModel.custom_properties != null
    ? eventModel.custom_properties.indexOf(invalidString) == 0
      ? null
      : typeof eventModel.custom_properties == "string"
      ? JSON.parse(eventModel.custom_properties)
      : eventModel.custom_properties
    : {};
for (const property in customProperties) {
  event.custom_data[property] = customProperties[property];
}
event.custom_data.num_items = FB_PARAMS_MAPPINGS.num_items || eventModel["x-fb-cd-num_items"];
event.custom_data.predicted_ltv =
  FB_PARAMS_MAPPINGS.predicted_ltv || eventModel["x-fb-cd-predicted_ltv"];
event.custom_data.status = FB_PARAMS_MAPPINGS.status || eventModel["x-fb-cd-status"];
event.custom_data.delivery_category =
  FB_PARAMS_MAPPINGS.delivery_category || eventModel["x-fb-cd-delivery_category"];

event.data_processing_options =
  FB_PARAMS_MAPPINGS.data_processing_options || eventModel.data_processing_options;
event.data_processing_options_country =
  FB_PARAMS_MAPPINGS.data_processing_options_country || eventModel.data_processing_options_country;
event.data_processing_options_state =
  FB_PARAMS_MAPPINGS.data_processing_options_state || eventModel.data_processing_options_state;

function setGtmEecCookie(value) {
  const cookieJsonStr = JSON.stringify(value);

  const gtmeecCookieValueBase64 = toBase64(cookieJsonStr);

  setHttpOnlyCookie("_gtmeec", gtmeecCookieValueBase64);
}

//sets first party cookie with latest merged user data.
function setResponseHeaderCookies(user_data) {
  let gtmeecCookie = {};

  // if user_data has new information, gtmeec data is overriden
  if (user_data.em) {
    gtmeecCookie.em = user_data.em;
  }

  if (user_data.ph) {
    gtmeecCookie.ph = user_data.ph;
  }

  if (user_data.ln) {
    gtmeecCookie.ln = user_data.ln;
  }

  if (user_data.fn) {
    gtmeecCookie.fn = user_data.fn;
  }

  if (user_data.ct) {
    gtmeecCookie.ct = user_data.ct;
  }

  if (user_data.st) {
    gtmeecCookie.st = user_data.st;
  }

  if (user_data.zp) {
    gtmeecCookie.zp = user_data.zp;
  }

  if (user_data.ge) {
    gtmeecCookie.ge = user_data.ge;
  }

  if (user_data.db) {
    gtmeecCookie.db = user_data.db;
  }

  if (user_data.country) {
    gtmeecCookie.country = user_data.country;
  }

  if (user_data.external_id) {
    gtmeecCookie.external_id = user_data.external_id;
  }

  if (user_data.fb_login_id) {
    gtmeecCookie.fb_login_id = user_data.fb_login_id;
  }

  setGtmEecCookie(gtmeecCookie);
}

//enhance event data with first party `_gtmeec` cookie
function enhanceEventData(user_data) {
  const cookieValues = getCookieValues("_gtmeec", true);

  if (!cookieValues) {
    return user_data;
  }

  if (cookieValues.length == 0) {
    return user_data;
  }

  const encodedValue = cookieValues[0];

  if (!encodedValue) {
    return user_data;
  }

  const jsonStr = fromBase64(encodedValue);
  if (!jsonStr) {
    return user_data;
  }

  const gtmeecData = JSON.parse(jsonStr);

  // if incoming event has already have the customer information then don't change
  if (gtmeecData) {
    if (!user_data.em && gtmeecData.em) {
      user_data.em = gtmeecData.em;
    }

    if (!user_data.ph && gtmeecData.ph) {
      user_data.ph = gtmeecData.ph;
    }

    if (!user_data.ln && gtmeecData.ln) {
      user_data.ln = gtmeecData.ln;
    }

    if (!user_data.fn && gtmeecData.fn) {
      user_data.fn = gtmeecData.fn;
    }

    if (!user_data.ct && gtmeecData.ct) {
      user_data.ct = gtmeecData.ct;
    }

    if (!user_data.st && gtmeecData.st) {
      user_data.st = gtmeecData.st;
    }

    if (!user_data.zp && gtmeecData.zp) {
      user_data.zp = gtmeecData.zp;
    }

    if (!user_data.ge && gtmeecData.ge) {
      user_data.ge = gtmeecData.ge;
    }

    if (!user_data.db && gtmeecData.db) {
      user_data.db = gtmeecData.db;
    }

    if (!user_data.country && gtmeecData.country) {
      user_data.country = gtmeecData.country;
    }

    if (!user_data.external_id && gtmeecData.external_id) {
      user_data.external_id = gtmeecData.external_id;
    }

    if (!user_data.fb_login_id && gtmeecData.fb_login_id) {
      user_data.fb_login_id = gtmeecData.fb_login_id;
    }
  }

  return user_data;
}

//send events to CAPI Server
function sendEventToCapiServers(pixel_event, pixel_id, api_access_token, callback) {
  // if event enhancement is enabled then event data is enhanced
  let partnerAgent = PARTNER_AGENT;
  if (data.enableEventEnhancement) {
    pixel_event.user_data = enhanceEventData(pixel_event.user_data);
    partnerAgent = PARTNER_AGENT + "-ee";
  }

  const eventRequest = { data: [pixel_event], partner_agent: partnerAgent };

  if (eventModel.test_event_code || data.testEventCode) {
    eventRequest.test_event_code = eventModel.test_event_code
      ? eventModel.test_event_code
      : data.testEventCode;
  }

  const routeParams = "events?access_token=" + api_access_token;
  const graphEndpoint = [API_ENDPOINT, API_VERSION, pixel_id, routeParams].join("/");

  const requestHeaders = { headers: { "content-type": "application/json" }, method: "POST" };
  return sendHttpRequest(
    graphEndpoint,
    (statusCode, headers, response) => {
      const isSuccess = statusCode >= 200 && statusCode < 300;
      if (isSuccess) {
        if (data.extendCookies && pixel_event.user_data.fbc) {
          setFbCookie("_fbc", pixel_event.user_data.fbc);
        }

        if (data.extendCookies && pixel_event.user_data.fbp) {
          setFbCookie("_fbp", pixel_event.user_data.fbp);
        }

        if (data.enableEventEnhancement) {
          setResponseHeaderCookies(pixel_event.user_data);
        }
      }
      if (callback) callback(isSuccess);
    },
    requestHeaders,
    JSON.stringify(eventRequest)
  );
}

const pixelIdList = data.pixelId.split(",");
const accessTokenList = data.apiAccessToken.split(",");

let requestsToFinish = pixelIdList.length;
let hasError = false;

function onCompletion(success) {
  requestsToFinish = requestsToFinish - 1;
  if (!success) hasError = true;
  if (requestsToFinish === 0) {
    if (hasError) {
      data.gtmOnFailure();
    } else {
      data.gtmOnSuccess();
    }
  }
}

for (var i = 0; i < pixelIdList.length; i += 1) {
  var pId = pixelIdList[i].trim();
  var aToken = (accessTokenList[i] || accessTokenList[0]).trim();

  sendEventToCapiServers(event, pId, aToken, onCompletion);
}

// trkkn custom 2
function valueIsFilled(value) {
  if (
    typeof value === "undefined" ||
    value === "undefined" ||
    value === null ||
    value === "" ||
    value === "null" ||
    (getType(value) === "array" && (value[0] === "null" || value[0] === null)) ||
    (getType(value) === "array" && (value[0] === "undefined" || value[0] === undefined))
  ) {
    return false;
  }
  return true;
}

function fbCookieSlug() {
  const version = "fb";
  const domainIndex = "1";
  const timestamp = getTimestampMillis();
  return [version, domainIndex, timestamp].join(".");
}

function generateFBP() {
  const random = generateRandom(10000000, 9999999999);
  return [fbCookieSlug(), random].join(".");
}

function getIPAddress() {
  const setting = data.anonymizeIP;
  if (setting === "remove" || !eventModel.ip_override) return;

  if (setting === "extraAnonymisation") {
    return anonymizeIP(eventModel.ip_override);
  }

  // should never happen. But just to be sure.
  if (setting !== "ip_override") {
    log("ERROR unknown anonymizeIP setting:", data.anonymizeIP);
  }

  // default that FB tests do not fail.
  return eventModel.ip_override;
}

function anonymizeIP(ip) {
  if (ip.indexOf(".") >= 0) {
    // 1.1.1.1 --> 1.1.1.0
    return ip.split(".").slice(0, -1).join(".") + ".0";
  }
  // 2001:db8:85a3:8d3:1319:8a2e:370:7348 --> 2001:db8:85a3::
  return ip.split(":").slice(0, -5).join(":") + "::";
}

/* TRKKN Custom 2 END*/

___SERVER_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "read_event_data",
        "versionId": "1"
      },
      "param": [
        {
          "key": "eventDataAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "send_http",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedUrls",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "urls",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "https://graph.facebook.com/"
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "get_cookies",
        "versionId": "1"
      },
      "param": [
        {
          "key": "cookieAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "cookieNames",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "_fbp"
              },
              {
                "type": 1,
                "string": "_fbc"
              },
              {
                "type": 1,
                "string": "_gtmeec"
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "set_cookies",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedCookies",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "name"
                  },
                  {
                    "type": 1,
                    "string": "domain"
                  },
                  {
                    "type": 1,
                    "string": "path"
                  },
                  {
                    "type": 1,
                    "string": "secure"
                  },
                  {
                    "type": 1,
                    "string": "session"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "_fbc"
                  },
                  {
                    "type": 1,
                    "string": "*"
                  },
                  {
                    "type": 1,
                    "string": "*"
                  },
                  {
                    "type": 1,
                    "string": "any"
                  },
                  {
                    "type": 1,
                    "string": "any"
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "name"
                  },
                  {
                    "type": 1,
                    "string": "domain"
                  },
                  {
                    "type": 1,
                    "string": "path"
                  },
                  {
                    "type": 1,
                    "string": "secure"
                  },
                  {
                    "type": 1,
                    "string": "session"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "_fbp"
                  },
                  {
                    "type": 1,
                    "string": "*"
                  },
                  {
                    "type": 1,
                    "string": "*"
                  },
                  {
                    "type": 1,
                    "string": "any"
                  },
                  {
                    "type": 1,
                    "string": "any"
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "name"
                  },
                  {
                    "type": 1,
                    "string": "domain"
                  },
                  {
                    "type": 1,
                    "string": "path"
                  },
                  {
                    "type": 1,
                    "string": "secure"
                  },
                  {
                    "type": 1,
                    "string": "session"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "_gtmeec"
                  },
                  {
                    "type": 1,
                    "string": "*"
                  },
                  {
                    "type": 1,
                    "string": "*"
                  },
                  {
                    "type": 1,
                    "string": "secure"
                  },
                  {
                    "type": 1,
                    "string": "any"
                  }
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "logging",
        "versionId": "1"
      },
      "param": [
        {
          "key": "environments",
          "value": {
            "type": 1,
            "string": "debug"
          }
        }
      ]
    },
    "isRequired": true
  }
]

___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "pixelId",
    "displayName": "Pixel ID(s)",
    "simpleValueType": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ],
    "help": "For sending to multiple Pixel IDs provide a comma-separated list of pixel ids."
  },
  {
    "type": "TEXT",
    "name": "apiAccessToken",
    "displayName": "API Access Token(s)",
    "simpleValueType": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ],
    "help": "To use the Conversions API, you need an access token. If providing multiple Pixel IDs, provide a corresponding comma-separated list of Access Tokens. See <a href=\"https://developers.facebook.com/docs/marketing-api/conversions-api/get-started#access-token\">here</a> for generating an access token."
  },
  {
    "type": "TEXT",
    "name": "testEventCode",
    "displayName": "Test Event Code",
    "simpleValueType": true,
    "help": "Code used to verify that your server events are received correctly by Conversions API. Use this code to test your server events in the Test Events feature in Events Manager. See <a href=\"https://developers.facebook.com/docs/marketing-api/conversions-api/using-the-api#testEvents\"> Test Events Tool</a> for an example."
  },
  {
    "type": "SELECT",
    "name": "actionSource",
    "displayName": "Action Source",
    "macrosInSelect": false,
    "selectItems": [
      {
        "value": "website",
        "displayValue": "Website"
      },
      {
        "value": "email",
        "displayValue": "Email"
      },
      {
        "value": "app",
        "displayValue": "App"
      },
      {
        "value": "phone_call",
        "displayValue": "Phone Call"
      },
      {
        "value": "chat",
        "displayValue": "Chat"
      },
      {
        "value": "physical_store",
        "displayValue": "Physical Store"
      },
      {
        "value": "system_generated",
        "displayValue": "System Generated"
      },
      {
        "value": "other",
        "displayValue": "Other"
      }
    ],
    "simpleValueType": true,
    "help": "This field allows you to specify where your conversions occurred. Knowing where your events took place helps ensure your ads go to the right people. See <a href=\"https://developers.facebook.com/docs/marketing-api/conversions-api/parameters/server-event#action-source\">here</a> for more information."
  },
  {
    "type": "CHECKBOX",
    "name": "extendCookies",
    "checkboxText": "Extend Meta Pixel cookies (fbp/fbc)",
    "simpleValueType": true
  },
  {
    "type": "CHECKBOX",
    "name": "enableEventEnhancement",
    "checkboxText": "Enable Event Enhancement",
    "simpleValueType": true,
    "help": "Enable Use of HTTP Only Secure Cookie (gtmeec) to Enhance Event Data"
  },
  {
    "type": "SELECT",
    "name": "userDataAllowed",
    "displayName": "Allow Meta to track User Data",
    "macrosInSelect": true,
    "selectItems": [
      {
        "value": "allow",
        "displayValue": "allow"
      },
      {
        "value": "deny",
        "displayValue": "deny"
      }
    ],
    "simpleValueType": true,
    "help": "User Data is email, phone number, first name, last name, city, region, postal code, country, gender and birthdate. Setting this to 'deny' ensures Facebook can not track any of this information. When set to 'allow', the template will automatically pull these details from standard event fields or your custom mappings.",
    "alwaysInSummary": true,
    "defaultValue": "deny"
  },
  {
    "type": "SELECT",
    "name": "anonymizeIP",
    "displayName": "Anonymize IP",
    "macrosInSelect": true,
    "selectItems": [
      {
        "value": "ip_override",
        "displayValue": "ip_override from event data"
      },
      {
        "value": "remove",
        "displayValue": "Remove IP completly"
      },
      {
        "value": "extraAnonymisation",
        "displayValue": "Use anonymisation on ip_override"
      }
    ],
    "simpleValueType": true,
    "defaultValue": "ip_override",
    "help": "Not sure? Select 'ip_override from event data' (Facebook's recommended setting).",
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  },
  {
    "type": "SIMPLE_TABLE",
    "name": "customEventMapping",
    "displayName": "Event Name Mapping",
    "simpleTableColumns": [
      {
        "defaultValue": "",
        "displayName": "Incoming Event Name",
        "name": "event_name",
        "type": "TEXT"
      },
      {
        "defaultValue": "",
        "displayName": "Event Name for Facebook",
        "name": "event_name_facebook",
        "type": "TEXT"
      }
    ],
    "newRowButtonText": "Add Event Mapping",
    "help": "Map incoming events to Facebook events. (Important: Names require an exact match)."
  },
  {
    "type": "SIMPLE_TABLE",
    "name": "fbParameterMapping",
    "displayName": "FB Standard Parameter Mapping",
    "simpleTableColumns": [
      {
        "defaultValue": "",
        "displayName": "Parameter Key",
        "name": "fb_parameter_key",
        "type": "SELECT",
        "selectItems": [
          {
            "value": "currency",
            "displayValue": "currency"
          },
          {
            "value": "external_id",
            "displayValue": "external_id"
          },
          {
            "value": "subscription_id",
            "displayValue": "subscription_id"
          },
          {
            "value": "search_string",
            "displayValue": "search_string"
          },
          {
            "value": "order_id",
            "displayValue": "order_id"
          },
          {
            "value": "content_category",
            "displayValue": "content_category"
          },
          {
            "value": "content_ids",
            "displayValue": "content_ids"
          },
          {
            "value": "content_name",
            "displayValue": "content_name"
          },
          {
            "value": "content_type",
            "displayValue": "content_type"
          },
          {
            "value": "contents",
            "displayValue": "contents"
          },
          {
            "value": "num_items",
            "displayValue": "num_items"
          },
          {
            "value": "predicted_ltv",
            "displayValue": "predicted_ltv"
          },
          {
            "value": "status",
            "displayValue": "status"
          },
          {
            "value": "delivery_category",
            "displayValue": "delivery_category"
          },
          {
            "value": "user_agent",
            "displayValue": "user_agent"
          },
          {
            "value": "event_id",
            "displayValue": "event_id"
          },
          {
            "value": "user_email",
            "displayValue": "user_email"
          },
          {
            "value": "user_phone_number",
            "displayValue": "user_phone_number"
          },
          {
            "value": "page_referrer",
            "displayValue": "page_referrer"
          },
          {
            "value": "country",
            "displayValue": "country"
          },
          {
            "value": "user_gender",
            "displayValue": "user_gender"
          },
          {
            "value": "user_date_birth",
            "displayValue": "user_date_birth"
          },
          {
            "value": "data_processing_options",
            "displayValue": "data_processing_options"
          },
          {
            "value": "data_processing_options_country",
            "displayValue": "data_processing_options_country"
          },
          {
            "value": "data_processing_options_state",
            "displayValue": "data_processing_options_state"
          }
        ]
      },
      {
        "defaultValue": "",
        "displayName": "Value",
        "name": "fb_parameter_value",
        "type": "TEXT"
      }
    ],
    "alwaysInSummary": false,
    "newRowButtonText": "Add FB Parameter Mapping",
    "help": "By default, parameters are pulled from standard event data. Add a mapping here to use a custom event data field instead."
  },
  {
    "type": "SIMPLE_TABLE",
    "name": "customParameterMapping",
    "displayName": "Add Custom Facebook Parameter",
    "simpleTableColumns": [
      {
        "defaultValue": "",
        "displayName": "Facebook Custom Parameter Key",
        "name": "fb_cust_parameter_key",
        "type": "TEXT"
      },
      {
        "defaultValue": "",
        "displayName": "Value",
        "name": "fb_cust_parameter_value",
        "type": "TEXT"
      }
    ],
    "newRowButtonText": "Add Custom Parameter",
    "alwaysInSummary": true,
    "help": "Add custom parameters here for any data not included in Facebook's standard tracking."
  },
  {
    "type": "CHECKBOX",
    "name": "processTrkknRepostHits",
    "checkboxText": "Get Data from TRKKN Reposted Hits",
    "simpleValueType": true,
    "help": "Enable automatic process of reposted Facebook hits. Triggered by the TRKKN Web Template. Leave it unchecked, if you do not know what this means.",
    "defaultValue": false,
    "alwaysInSummary": true
  },
  {
    "type": "SELECT",
    "name": "repostDataSource",
    "displayName": "Data Source (needs to be a json string, unparsed)",
    "macrosInSelect": true,
    "selectItems": [
      {
        "value": "default",
        "displayValue": "default (fbData from Event Data)"
      }
    ],
    "simpleValueType": true,
    "help": "If 'default', the source is: fbDate, from event data. Switch to any available variable to customize your data flow.",
    "enablingConditions": [
      {
        "paramName": "processTrkknRepostHits",
        "paramValue": true,
        "type": "EQUALS"
      }
    ],
    "defaultValue": "default"
  },
  {
    "type": "LABEL",
    "name": "label1",
    "displayName": "________________________________________________________________________"
  },
  {
    "type": "LABEL",
    "name": "versionLabel",
    "displayName": "template version: 2.0.0, FB: 1.0.0 (July 23rd, 2025)"
  }
]

___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.

___TESTS___

scenarios:
  - name: on EventModel model data tag triggers to send to Conversions API
    code: |-
      // Act
      runCode(testConfigurationData);

      //Assert
      assertApi('sendHttpRequest').wasCalledWith(requestEndpoint, actualSuccessCallback, requestHeaderOptions, JSON.stringify(requestData));
      assertApi('gtmOnSuccess').wasCalled();
  - name: on Event with common event schema triggers tag to send to Conversions API
    code: |-
      const preTagFireEventTime = Math.round(getTimestampMillis() / 1000);
      const common_event_schema = {
          event_name: testData.event_name,
          client_id: 'client123',
          ip_override: testData.ip_address,
          user_agent: testData.user_agent,
        };
      mock('getAllEventData', () => {
        return common_event_schema;
      });

      // Act
      runCode(testConfigurationData);

      //Assert
      const actualTagFireEventTime = JSON.parse(httpBody).data[0].event_time;
      assertThat(actualTagFireEventTime-preTagFireEventTime).isLessThan(1);
      assertApi('gtmOnSuccess').wasCalled();
  - name: on sending action source from Client, Tag overrides the preset configuration
    code: |-
      // Act
      mock('getAllEventData', () => {
        inputEventModel.action_source = testData.action_source;
        return inputEventModel;
      });
      runCode(testConfigurationData);

      //Assert
      assertThat(JSON.parse(httpBody).data[0].action_source).isEqualTo(inputEventModel.action_source);
  - name: on receiving event, if GTM Standard Event then Tag converts to corresponding
      Conversions API Event, passes through as-is if otherwise
    code: |-
      // Act
      mock('getAllEventData', () => {
        inputEventModel.event_name = 'add_to_wishlist';
        return inputEventModel;
      });
      runCode(testConfigurationData);

      //Assert
      assertThat(JSON.parse(httpBody).data[0].event_name).isEqualTo('AddToWishlist');


      // Act
      mock('getAllEventData', () => {
        inputEventModel.event_name = 'custom_event';
        return inputEventModel;
      });
      runCode(testConfigurationData);

      //Assert
      assertThat(JSON.parse(httpBody).data[0].event_name).isEqualTo('custom_event');

      // Act
      mock('getAllEventData', () => {
        inputEventModel.event_name = 'generate_lead';
        return inputEventModel;
      });
      runCode(testConfigurationData);

      //Assert
      assertThat(JSON.parse(httpBody).data[0].event_name).isEqualTo('Lead');
  - name: On receiving event, hashes the the user_data fields if they are not already
      hashed
    code: |-
      // Un-hashed raw email_address from Common Event Schema is hashed before posted to Conversions API.

      // Act
      mock('getAllEventData', () => {
        inputEventModel = {};
        inputEventModel['x-fb-ud-em'] = null;
        inputEventModel['x-fb-ud-ph'] = null;
        inputEventModel['x-fb-ud-fn'] = null;
        inputEventModel['x-fb-ud-ln'] = null;
        inputEventModel['x-fb-ud-ct'] = null;
        inputEventModel['x-fb-ud-st'] = null;
        inputEventModel['x-fb-ud-zp'] = null;
        inputEventModel['x-fb-ud-country'] = null;
        inputEventModel.user_data = {};
        inputEventModel.user_data.email_address = 'foo@bar.com';
        inputEventModel.user_data.phone_number = '1234567890';
        inputEventModel.user_data.address = {};
        inputEventModel.user_data.address.first_name = 'Foo';
        inputEventModel.user_data.address.last_name = 'Bar';
        inputEventModel.user_data.address.city = 'Menlo Park';
        inputEventModel.user_data.address.region = 'ca';
        inputEventModel.user_data.address.postal_code = '12345';
        inputEventModel.user_data.address.country = 'usa';
        return inputEventModel;
      });
      runCode(testConfigurationData);

      //Assert
      assertThat(JSON.parse(httpBody).data[0].user_data.em).isEqualTo(hashFunction('foo@bar.com'));
      assertThat(JSON.parse(httpBody).data[0].user_data.ph).isEqualTo(hashFunction('1234567890'));
      assertThat(JSON.parse(httpBody).data[0].user_data.fn).isEqualTo(hashFunction('Foo'));
      assertThat(JSON.parse(httpBody).data[0].user_data.ln).isEqualTo(hashFunction('Bar'));
      assertThat(JSON.parse(httpBody).data[0].user_data.ct).isEqualTo(hashFunction('Menlo Park'));
      assertThat(JSON.parse(httpBody).data[0].user_data.st).isEqualTo(hashFunction('ca'));
      assertThat(JSON.parse(httpBody).data[0].user_data.zp).isEqualTo(hashFunction('12345'));
      assertThat(JSON.parse(httpBody).data[0].user_data.country).isEqualTo(hashFunction('usa'));

      // Un-hashed raw email_address in mixed-case is converted to lowercase, hashed and posted to Conversions API.

      // Act
      mock('getAllEventData', () => {
        inputEventModel.user_data.email_address = 'FOO@BAR.com';
        return inputEventModel;
      });
      runCode(testConfigurationData);

      //Assert
      assertThat(JSON.parse(httpBody).data[0].user_data.em).isEqualTo(hashFunction('foo@bar.com'));


      // Already sha256(email_address) field from GA4 schema, is unchanged, is posted as-is to Conversions API.

      // Act
      mock('getAllEventData', () => {
        inputEventModel.user_data.email_address = hashFunction('foo@bar.com');
        return inputEventModel;
      });
      runCode(testConfigurationData);

      //Assert
      assertThat(JSON.parse(httpBody).data[0].user_data.em).isEqualTo(hashFunction('foo@bar.com'));

      // Already null email field from GA4 schema, is sent as null to Conversions API.

      // Act
      mock('getAllEventData', () => {
        inputEventModel = {};
        inputEventModel.user_data = {};
        inputEventModel.user_data.sha256_email_address = null;
        return inputEventModel;
      });
      runCode(testConfigurationData);

      //Assert
      assertThat(JSON.parse(httpBody).data[0].user_data.em).isNull();
  - name: On receiving event with fbp/fbc cookies, it is sent to Conversions API
    code: |-
      // Act
      mock('getAllEventData', () => {
        inputEventModel['x-fb-ck-fbp'] = null;
        inputEventModel['x-fb-ck-fbc'] = null;
        return inputEventModel;
      });

      mock('getCookieValues', (cookieName) => {
        if(cookieName === '_fbp') return ['fbp_cookie'];
        if(cookieName === '_fbc') return ['fbc_cookie'];
      });

      runCode(testConfigurationData);

      //Assert
      assertThat(JSON.parse(httpBody).data[0].user_data.fbp).isEqualTo('fbp_cookie');
      assertThat(JSON.parse(httpBody).data[0].user_data.fbc).isEqualTo('fbc_cookie');
  - name: On receiving GA4 event, with the items info, tag parses them into Conversions
      API schema
    code: |-
      // Act
      let items = [
          {
            item_id: '1',
            quantity: 5,
            price: 123.45,
          },
          {
            item_id: '2',
            quantity: 10,
            price: 123.45,
          }
        ];

      mock('getAllEventData', () => {
        inputEventModel = {};
        inputEventModel['x-fb-cd-contents'] = null;
        inputEventModel.items = items;
        return inputEventModel;
      });
      runCode(testConfigurationData);

      //Assert
      let actual_contents = JSON.parse(httpBody).data[0].custom_data.contents;
      assertThat(JSON.parse(httpBody).data[0].custom_data.contents.length).isEqualTo(items.length);
      for( var i = 0; i < items.length; i++) {
        assertThat(actual_contents[i].id).isEqualTo(items[i].item_id);
        assertThat(actual_contents[i].item_price).isEqualTo(items[i].price);
        assertThat(actual_contents[i].quantity).isEqualTo(items[i].quantity);
      }

      // Act
      mock('getAllEventData', () => {
        inputEventModel = {};
        inputEventModel.items = null;
        return inputEventModel;
      });
      runCode(testConfigurationData);

      //Assert
      assertThat(JSON.parse(httpBody).data[0].custom_data.contents).isUndefined();
  - name: When address is missing it skips parsing the nested fields
    code: |
      mock('getAllEventData', () => {
        inputEventModel['x-fb-ud-em'] = null;
        inputEventModel['x-fb-ud-ph'] = null;
        inputEventModel['x-fb-ud-fn'] = null;
        inputEventModel['x-fb-ud-ln'] = null;
        inputEventModel['x-fb-ud-ct'] = null;
        inputEventModel['x-fb-ud-st'] = null;
        inputEventModel['x-fb-ud-zp'] = null;
        inputEventModel['x-fb-ud-country'] = null;
        inputEventModel.user_data = {};
        inputEventModel.user_data.email_address = 'foo@bar.com';
        inputEventModel.user_data.phone_number = '1234567890';
        return inputEventModel;
      });

      runCode(testConfigurationData);

      assertThat(JSON.parse(httpBody).data[0].user_data.em).isEqualTo(hashFunction('foo@bar.com'));
      assertThat(JSON.parse(httpBody).data[0].user_data.ph).isEqualTo(hashFunction('1234567890'));
      assertThat(JSON.parse(httpBody).data[0].user_data.fn).isUndefined();
      assertThat(JSON.parse(httpBody).data[0].user_data.ln).isUndefined();
      assertThat(JSON.parse(httpBody).data[0].user_data.ct).isUndefined();
      assertThat(JSON.parse(httpBody).data[0].user_data.st).isUndefined();
      assertThat(JSON.parse(httpBody).data[0].user_data.zp).isUndefined();
      assertThat(JSON.parse(httpBody).data[0].user_data.country).isUndefined();
  - name: When parameters are undefined skip parsing
    code: |
      mock('getAllEventData', () => {
        inputEventModel = {};
        inputEventModel['x-fb-ud-em'] = null;
        inputEventModel['x-fb-ud-ph'] = null;
        inputEventModel['x-fb-ud-fn'] = null;
        inputEventModel['x-fb-ud-ln'] = null;
        inputEventModel['x-fb-ud-ct'] = null;
        inputEventModel['x-fb-ud-st'] = null;
        inputEventModel['x-fb-ud-zp'] = null;
        inputEventModel['x-fb-ud-country'] = null;
        inputEventModel['x-fb-ud-fb-login-id'] = null;
        inputEventModel.user_data = {};
        inputEventModel.user_data.email_address = undefined;
        inputEventModel.user_data.phone_number = '1234567890';
        inputEventModel.user_data.address = {};
        inputEventModel.user_data.address.first_name = 'John';
        inputEventModel.user_data.address.last_name = undefined;
        inputEventModel.user_data.address.city = 'menlopark';
        inputEventModel.user_data.address.region = 'ca';
        inputEventModel.user_data.address.postal_code = '94025';
        inputEventModel.user_data.address.country = 'usa';
        inputEventModel.user_data.fb_login_id = 123456789;
        return inputEventModel;
      });

      runCode(testConfigurationData);

      assertThat(JSON.parse(httpBody).data[0].user_data.em).isUndefined();
      assertThat(JSON.parse(httpBody).data[0].user_data.ph).isEqualTo(hashFunction('1234567890'));
      assertThat(JSON.parse(httpBody).data[0].user_data.fn).isEqualTo(hashFunction('John'));
      assertThat(JSON.parse(httpBody).data[0].user_data.ln).isUndefined();
      assertThat(JSON.parse(httpBody).data[0].user_data.ct).isEqualTo(hashFunction('menlopark'));
      assertThat(JSON.parse(httpBody).data[0].user_data.st).isEqualTo(hashFunction('ca'));
      assertThat(JSON.parse(httpBody).data[0].user_data.zp).isEqualTo(hashFunction('94025'));
      assertThat(JSON.parse(httpBody).data[0].user_data.country).isEqualTo(hashFunction('usa'));
      assertThat(JSON.parse(httpBody).data[0].user_data.fb_login_id).isEqualTo(123456789);
  - name: Set Meta cookies (fbp / fbc) if 'extendCookies' checkbox is ticked
    code: |
      runCode({
        pixelId: '123',
        apiAccessToken: 'abc',
        testEventCode: 'test123',
        actionSource: 'source123',
        extendCookies: true
      });

      //Assert
      assertApi('setCookie').wasCalled();
      assertApi('gtmOnSuccess').wasCalled();
  - name: Do not set Meta cookies (fbp / fbc) if 'extendCookies' checkbox is ticked
    code: |
      runCode({
        pixelId: '123',
        apiAccessToken: 'abc',
        testEventCode: 'test123',
        actionSource: 'source123',
        extendCookies: false
      });

      //Assert
      assertApi('setCookie').wasNotCalled();
      assertApi('gtmOnSuccess').wasCalled();
  - name: On receiving event, sets the data_processing_options field if present
    code: |
      mock('getAllEventData', () => {
        inputEventModel.data_processing_options = testData.data_processing_options;
        inputEventModel.data_processing_options_country = testData.data_processing_options_country;
        inputEventModel.data_processing_options_state = testData.data_processing_options_state;
        return inputEventModel;
      });
      runCode(testConfigurationData);

      //Assert
      assertThat(JSON.parse(httpBody).data[0].data_processing_options).isEqualTo(inputEventModel.data_processing_options);
      assertThat(JSON.parse(httpBody).data[0].data_processing_options_country).isEqualTo(inputEventModel.data_processing_options_country);
      assertThat(JSON.parse(httpBody).data[0].data_processing_options_state).isEqualTo(inputEventModel.data_processing_options_state);
  - name: Set Event Enhancement Cookie (gtmeec) if `enableEventEnhancement` is ticked
    code: |-
      mock('getAllEventData', () => {
        inputEventModel = {};
        inputEventModel.event_name = 'purchase';
        inputEventModel.user_data = {};
        inputEventModel.user_data.email_address = 'foo@bar.com';
        inputEventModel.user_data.phone_number = '1234567890';
        return inputEventModel;
      });

      runCode(testConfigurationData);

      runCode({
        pixelId: '123',
        apiAccessToken: 'abc',
        testEventCode: 'test123',
        actionSource: 'source123',
        enableEventEnhancement: true,
        extendCookies: false,
        userDataAllowed: "allow",
      });

      let cookieOptions = {
          domain: 'auto',
          path: '/',
          samesite: 'strict',
          secure: true,
          'max-age': 7776000, // default to 90 days
          httpOnly: true
      };

      //Assert
      assertApi('getCookieValues').wasCalledWith('_gtmeec', true);
      assertApi('setCookie').wasCalledWith('_gtmeec', 'eyJlbSI6IjBjN2U2YTQwNTg2MmU0MDJlYjc2YTcwZjhhMjZmYzczMmQwN2MzMjkzMWU5ZmFlOWFiMTU4MjkxMWQyZThhM2IiLCJwaCI6ImM3NzVlN2I3NTdlZGU2MzBjZDBhYTExMTNiZDEwMjY2MWFiMzg4MjljYTUyYTY0MjJhYjc4Mjg2MmYyNjg2NDYifQ==', cookieOptions);
      assertApi('gtmOnSuccess').wasCalled();
  - name: Do not set Event Enhancement Cookie (gtmeec) if `enableEventEnhancement` is
      not ticked
    code: |-
      runCode({
        pixelId: '123',
        apiAccessToken: 'abc',
        testEventCode: 'test123',
        actionSource: 'source123',
        extendCookies: false,
        enableEventEnhancement: false
      });

      //Assert
      assertApi('getCookieValues').wasNotCalledWith('_gtmeec', true);
      assertApi('setCookie').wasNotCalled();
      assertApi('gtmOnSuccess').wasCalled();
  - name: Parse gtmeec Cookie and Enrich Event When `enableEventEnhancement` is ticked
    code: |
      mock('getAllEventData', () => {
        inputEventModel = {};
        inputEventModel.event_name = 'purchase';
        inputEventModel.user_data = {};
        return inputEventModel;
      });

      runCode(testConfigurationData);

      const cookieName = '_gtmeec';
      const val = true;

      mock('getCookieValues', (cookieName, val) => {
        return ['eyJlbSI6ImVlMjc4OTQzZGU4NGU1ZDYyNDM1NzhlZTFhMTA1N2JjY2UwZTUwZGFhZDk3NTVmNDVkZmE2NGI2MGIxM2JjNWQiLCJwaCI6ImM3NzVlN2I3NTdlZGU2MzBjZDBhYTExMTNiZDEwMjY2MWFiMzg4MjljYTUyYTY0MjJhYjc4Mjg2MmYyNjg2NDYifQ=='];
      });

      runCode({
        pixelId: '123',
        apiAccessToken: 'abc',
        testEventCode: 'test123',
        actionSource: 'source123',
        enableEventEnhancement: true,
        extendCookies: false
      });

      let cookieOptions = {
          domain: 'auto',
          path: '/',
          samesite: 'strict',
          secure: true,
          'max-age': 7776000, // default to 90 days
          httpOnly: true
      };

      // Assert
      assertApi('getCookieValues').wasCalledWith('_gtmeec', true);
      assertApi('setCookie').wasCalledWith('_gtmeec', 'eyJlbSI6ImVlMjc4OTQzZGU4NGU1ZDYyNDM1NzhlZTFhMTA1N2JjY2UwZTUwZGFhZDk3NTVmNDVkZmE2NGI2MGIxM2JjNWQiLCJwaCI6ImM3NzVlN2I3NTdlZGU2MzBjZDBhYTExMTNiZDEwMjY2MWFiMzg4MjljYTUyYTY0MjJhYjc4Mjg2MmYyNjg2NDYifQ==', cookieOptions);
      assertApi('gtmOnSuccess').wasCalled();

      assertThat(JSON.parse(httpBody).data[0].user_data.em).isEqualTo('ee278943de84e5d6243578ee1a1057bcce0e50daad9755f45dfa64b60b13bc5d');
      assertThat(JSON.parse(httpBody).data[0].user_data.ph).isEqualTo('c775e7b757ede630cd0aa1113bd102661ab38829ca52a6422ab782862f268646');
  - name: Grab the hashed email and phone number, check that isn't double hashed
    code: |
      mock("getAllEventData", () => {
        inputEventModel = {};
        inputEventModel.user_data = {};
        inputEventModel.user_data.sha256_email_address = "0c7e6a405862e402eb76a70f8a26fc732d07c32931e9fae9ab1582911d2e8a3b";
        inputEventModel.user_data.sha256_phone_number = "c775e7b757ede630cd0aa1113bd102661ab38829ca52a6422ab782862f268646";
        return inputEventModel;
      });

      runCode(testConfigurationData);

      //Assert
      assertThat(JSON.parse(httpBody).data[0].user_data.em).isEqualTo(hashFunction("0c7e6a405862e402eb76a70f8a26fc732d07c32931e9fae9ab1582911d2e8a3b"));
      assertThat(JSON.parse(httpBody).data[0].user_data.ph).isEqualTo(hashFunction("c775e7b757ede630cd0aa1113bd102661ab38829ca52a6422ab782862f268646"));
  - name: Do not pass the email if User Data Tickbox isn't clicked
    code: |-
      mock("getAllEventData", () => {
        inputEventModel = {};
        inputEventModel.user_data = {};
        inputEventModel.user_data.sha256_email_address = "0c7e6a405862e402eb76a70f8a26fc732d07c32931e9fae9ab1582911d2e8a3b";
        inputEventModel.user_data.sha256_phone_number = "c775e7b757ede630cd0aa1113bd102661ab38829ca52a6422ab782862f268646";
        return inputEventModel;
      });
      testConfigurationData.userDataAllowed = undefined;
      runCode(testConfigurationData);

      //Assert
      assertThat(JSON.parse(httpBody).data[0].user_data.em).isUndefined();
      assertThat(JSON.parse(httpBody).data[0].user_data.ph).isUndefined();
setup: |-
  // Arrange
  const JSON = require('JSON');
  const Math = require('Math');
  const getType = require("getType");
  const getTimestampMillis = require('getTimestampMillis');
  const sha256Sync = require('sha256Sync');
  const log = require('logToConsole');

  function hashFunction(input) {
    const type = getType(input);
      if (type == "undefined" || input == "undefined") {
        return undefined;
    }

  if (input == null || isAlreadyHashed(input)) {
    return input;
  }

  return sha256Sync(input.trim().toLowerCase(), { outputEncoding: "hex" });
  }

  function isAlreadyHashed(input) {
    return input && input.match("^[A-Fa-f0-9]{64}$") != null;
  }

  const testConfigurationData = {
    pixelId: '123',
    apiAccessToken: 'abc',
    testEventCode: 'test123',
    actionSource: 'source123',
    userDataAllowed: "allow",
    anonymizeIP : 'ip_override'
  };

  const testData = {
    event_name: "Test1",
    event_time: "123456789",
    test_event_code: "test123",
    action_source: 'website',
    user_data: {
      ip_address: '1.2.3.4',
      user_agent: 'Test_UA',
      email: 'test@example.com',
      phone_number: '123456789',
      first_name: 'foo',
      last_name: 'bar',
      gender: 'm',
      date_of_brith: '19910526',
      city: 'menlopark',
      state: 'ca',
      country: 'us',
      zip: '12345',
      external_id: 'user123',
      subscription_id: 'abc123',
      fbp: 'test_browser_id',
      fbc: 'test_click_id',
      fb_login_id: 123456789,
    },
    custom_data: {
      currency: 'USD',
      value: '123',
      search_string: 'query123',
      transaction_id: 'order_123',
      content_category: 'testCategory',
      content_ids: ['123', '456'],
      content_name: 'Foo',
      content_type: 'product',
      contents:  [{'id': '123', 'quantity': 2}, {'id': '456', 'quantity': 2}],
      num_items: '4',
      predicted_ltv: '10000',
      delivery_category: 'home_delivery',
      status: 'subscribed',
    },
    "data_processing_options": ["LDU"],
    "data_processing_options_country": 1,
    "data_processing_options_state": 1000,
  };

  let inputEventModel = {
    'event_name': testData.event_name,
    'event_time': testData.event_time,
    'ip_override': testData.user_data.ip_address,
    'user_agent': testData.user_data.user_agent,
    'test_event_code': testData.test_event_code,
    'x-fb-ud-em': testData.user_data.email,
    'x-fb-ud-ph': testData.user_data.phone_number,
    'x-fb-ud-fn': testData.user_data.first_name,
    'x-fb-ud-ln': testData.user_data.last_name,
    'x-fb-ud-ge': testData.user_data.gender,
    'x-fb-ud-db': testData.user_data.date_of_brith,
    'x-fb-ud-ct': testData.user_data.city,
    'x-fb-ud-st': testData.user_data.state,
    'x-fb-ud-zp': testData.user_data.zip,
    'x-fb-ud-country': testData.user_data.country,
    'x-fb-ud-external_id': testData.user_data.external_id,
    'x-fb-ud-subscription_id': testData.user_data.subscription_id,
    'x-fb-ud-fb-login-id': testData.user_data.fb_login_id,
    'x-fb-ck-fbp': testData.user_data.fbp,
    'x-fb-ck-fbc': testData.user_data.fbc,
    'currency': testData.custom_data.currency,
    'value': testData.custom_data.value,
    'search_term': testData.custom_data.search_string,
    'transaction_id': testData.custom_data.transaction_id,
    'x-fb-cd-status': testData.custom_data.status,
    'x-fb-cd-content_category': testData.custom_data.content_category,
    'x-fb-cd-content_name': testData.custom_data.content_name,
    'x-fb-cd-content_type': testData.custom_data.content_type,
    'x-fb-cd-contents': testData.custom_data.contents,
    'x-fb-cd-num_items': testData.custom_data.num_items,
    'x-fb-cd-predicted_ltv': testData.custom_data.predicted_ltv,
    'x-fb-cd-delivery_category': testData.custom_data.delivery_category,
    'data_processing_options': testData.data_processing_options,
    'data_processing_options_country': testData.data_processing_options_country,
    'data_processing_options_state': testData.data_processing_options_state,
  };

  const expectedEventData = {
  'event_name': testData.event_name,
  'event_time': testData.event_time,
  'action_source': testConfigurationData.actionSource,
  'user_data': {
    'client_ip_address': testData.user_data.ip_address,
    'client_user_agent': testData.user_data.user_agent,
    'em': hashFunction(testData.user_data.email),
    'ph': testData.user_data.phone_number,
    'fn': testData.user_data.first_name,
    'ln': testData.user_data.last_name,
    'ct': testData.user_data.city,
    'st': testData.user_data.state,
    'zp': testData.user_data.zip,
    'country': testData.user_data.country,
    'ge': testData.user_data.gender,
    'db': testData.user_data.date_of_brith,
    'external_id': testData.user_data.external_id,
    'subscription_id': testData.user_data.subscription_id,
    'fbp': testData.user_data.fbp,
    'fbc': testData.user_data.fbc,
    'fb_login_id': testData.user_data.fb_login_id,
  },
    'custom_data': {
      'currency': testData.custom_data.currency,
      'value': testData.custom_data.value,
      'search_string': testData.custom_data.search_string,
      'order_id': testData.custom_data.transaction_id,
      'content_category': testData.custom_data.content_category,
      'content_name': testData.custom_data.content_name,
      'content_type': testData.custom_data.content_type,
      'contents': testData.custom_data.contents,
      'num_items': testData.custom_data.num_items,
      'predicted_ltv': testData.custom_data.predicted_ltv,
      'status': testData.custom_data.status,
      'delivery_category': testData.custom_data.delivery_category,
    },
    'data_processing_options': testData.data_processing_options,
    'data_processing_options_country': testData.data_processing_options_country,
    'data_processing_options_state': testData.data_processing_options_state,
  };

  mock('getAllEventData', () => {
    return inputEventModel;
  });

  const apiEndpoint = 'https://graph.facebook.com';
  const apiVersion = 'v16.0';
  const partnerAgent = 'trkkn-2.0.0';

  const routeParams = 'events?access_token=' + testConfigurationData.apiAccessToken;
  const requestEndpoint = [apiEndpoint,
                          apiVersion,
                          testConfigurationData.pixelId,
                          routeParams].join('/');

  let requestData = {
                      data: [expectedEventData],
                      partner_agent: partnerAgent,
                      test_event_code: testData.test_event_code
                     };

  const requestHeaderOptions = {headers: {'content-type': 'application/json'}, method: 'POST'};

  let actualSuccessCallback, httpBody;
  mock('sendHttpRequest', (postUrl, response, options, body) => {
    log(body);
    actualSuccessCallback = response;
    httpBody = body;
    actualSuccessCallback(200, {}, '');
  });
