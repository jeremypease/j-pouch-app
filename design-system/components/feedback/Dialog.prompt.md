Bottom sheet modal — confirm delete, add-entry detail, medication reminder detail. Slides up from the bottom, scrim behind.

```jsx
<Dialog open={open} title="Delete entry?" onClose={close} footer={<><Button variant="ghost">Cancel</Button><Button variant="danger">Delete</Button></>}>This can't be undone.</Dialog>
```
