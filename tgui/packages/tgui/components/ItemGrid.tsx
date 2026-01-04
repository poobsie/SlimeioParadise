import { ReactNode } from 'react';
import { Box, Button, ImageButton } from 'tgui-core/components';

export type ItemGridItem = {
  key: string;
  name: string;
  icon: string;
  iconState: string;
  selected?: boolean;
  disabled?: boolean;
  tooltip?: ReactNode;
  tooltipPosition?: 'top' | 'top-start' | 'top-end' | 'bottom' | 'bottom-start' | 'bottom-end' | 'left' | 'left-start' | 'left-end' | 'right' | 'right-start' | 'right-end';
  buttons?: ReactNode;
  topLabel?: ReactNode;
  bottomLabel?: ReactNode;
  onClick?: () => void;
};

type ItemGridProps = {
  items: ItemGridItem[];
  imageSize?: number;
  showLabels?: boolean;
  labelPosition?: 'top' | 'bottom';
  className?: string;
};

/**
 * A generic grid component for displaying items with icons, labels, and interactive elements.
 * 
 * @param items - Array of items to display in the grid
 * @param imageSize - Size of the item icons (default: 84)
 * @param showLabels - Whether to show item labels (default: true)
 * @param labelPosition - Position of labels relative to buttons ('top' or 'bottom', default: 'bottom')
 * @param className - Optional CSS class name for styling
 */
export const ItemGrid = (props: ItemGridProps) => {
  const {
    items,
    imageSize = 84,
    showLabels = true,
    labelPosition = 'bottom',
    className,
  } = props;

  return (
    <>
      {items.map((item) => {
        const buttonsAlt = showLabels && labelPosition === 'bottom' ? item.bottomLabel : undefined;
        const buttonsTop = showLabels && labelPosition === 'top' ? item.topLabel : undefined;

        return (
          <ImageButton
            key={item.key}
            m={0.5}
            className={className}
            imageSize={imageSize}
            dmIcon={item.icon}
            dmIconState={item.iconState}
            tooltip={item.tooltip}
            tooltipPosition={item.tooltipPosition || 'bottom'}
            selected={item.selected}
            disabled={item.disabled}
            buttons={item.buttons}
            buttonsAlt={buttonsAlt || buttonsTop}
            onClick={item.onClick}
          >
            {item.name}
          </ImageButton>
        );
      })}
    </>
  );
};
