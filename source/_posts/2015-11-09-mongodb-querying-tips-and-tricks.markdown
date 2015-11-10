---
layout: post
title: "MongoDB Querying Tips And Tricks"
date: 2015-11-09 10:35
comments: true
categories: [MongoDB, DigData]
---

This post contains a bunch of tricks I picked up over the years working with MongoDB. They are also implemented in [MQL](http://digdata.io) as helper functions.

## Filter on creation time

Did you know you can filter on creation time without adding a timestamp field?

By default, a document's _id field contains an ObjectId. This ObjectId is composed from several values: number of seconds from the epoch, machine identifier, process identifier and a counter.

Since the ObjectId starts with a timestamp you can order by it or use it for filtering. The following function generates an ObjectId from a python datetime object:

{% codeblock lang:python %}

import datetime, time, bson

def oid_from_date(dt):
    seconds_from_epoch = int(time.mktime(dt.timetuple()))
    return bson.ObjectId(hex(seconds_from_epoch)[2:] + '0' * 16)

>>> oid_from_date(datetime.datetime(2015, 7, 4, 12, 0, 0))
ObjectId('5597a0900000000000000000')

{% endcodeblock %}

We can now use this for querying documents in a specific range:

{% codeblock lang:python %}

>>> connection.test.test.find({_id: {'$gt': oid_from_date(datetime.datetime(2015, 7, 3)), '$lt': oid_from_date(datetime.datetime(2015, 7, 4))}})

{% endcodeblock %}

Here's how you would do it with [MQL](http://digdata.io):

{% codeblock lang:sql %}

select * from test.test where _id between oidFromDate('2015-07-03') and oidFromDate('2015-07-04')

{% endcodeblock %}

## Convert datetime to date

It's often useful to aggregate data in different time resolutions: yearly, monthly, daily, etc'.

MongoDB lets us group by several fields but having a seperate field for year, month and day isn't natural.

As of MongoDB 3.0 there's a builtin function called [dateToString](https://docs.mongodb.org/v3.0/reference/operator/aggregation/dateToString/) that does exactly that. The following solution is useful if you're still on 2.6.

In order to generate a date from a datetime we can construct a number that contains the year, month and day. For example, the datetime `2015-07-04 12:00:00` can be represented as a date using a number: `20150704`. Here's how you would do it with [MQL](http://digdata.io):

{% codeblock lang:sql %}

select year(timestamp) * 10000 + month(timestamp) * 100 + dayOfMonth(timestamp) as date from test.test

{% endcodeblock %}

There's a builtin helper function that generates the same expression:

{% codeblock lang:sql %}

select extractDate(timestamp) as date from test.test

{% endcodeblock %}

Here's how you can do it with MongoDB's aggregation framework:

{% codeblock lang:python %}

connection.test.test.aggregate([
  {'$project': 
    {'date': 
      {'$add': [{'$multiply': [{'$year': '$timestamp'}, 10000]},
                {'$multiply': [{'$month': '$timestamp'}, 100]},
                {'$dayOfMonth': '$timestamp']}}}
])

{% endcodeblock %}

You can use the same concept for aggregating on other resolutions using additional functions like `$hour` and `$minute`.

## Floating point manipulation

`floor` has been introduced in MongoDB 3.2 but since it's not out yet, you can do the following:

{% codeblock lang:python %}

connection.test.test.aggregate([
  {'$project': 
    {'number': {'$subtract': ['$number', {'$mod': ['$number', 1]}]}}}
])

{% endcodeblock %}

Here's how you would do it with [MQL](http://digdata.io):

{% codeblock lang:sql %}

select number - number % 1 from test.test

{% endcodeblock %}

There's a builtin helper function that generates the same expression:

{% codeblock lang:sql %}

select toInt(number) from test.test

{% endcodeblock %}

## Compare fields

MongoDB's `find()` doesn't support comparing fields but the aggregation framework gives us the building blocks to implement it:

{% codeblock lang:python %}

connection.test.test.aggregate([
  {'$project': 
    {'a = b': {'$eq': ['$a', '$b']}}},
  {'$match':
    {'a = b': True}}
])

{% endcodeblock %}

Here's how you would do it with [MQL](http://digdata.io):

{% codeblock lang:sql %}

select a from test.test where a=b

{% endcodeblock %}
